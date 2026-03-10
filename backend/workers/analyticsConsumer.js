/**
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * ANALYTICS CONSUMER WORKER
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * Reads from Redis Streams (analytics:events) and batches
 * writes to Cassandra every 5 seconds.
 *
 * Run as a separate process: node workers/analyticsConsumer.js
 */
require('dotenv').config();
const { loadConfig } = require('../src/config/env');
loadConfig();

const { connectRedis, getRedis, disconnectRedis } = require('../src/services/redisService');
const { connectCassandra, shutdownCassandra, updateDrugUsageCounters, writeInteractionAnalytics } = require('../src/services/cassandraService');
const { logger } = require('../src/middleware/logger');

const STREAM_KEY = 'analytics:events';
const CONSUMER_GROUP = 'analytics-workers';
const CONSUMER_NAME = `worker-${process.pid}`;
const BATCH_INTERVAL_MS = 5000;
const BATCH_SIZE = 100;

async function ensureConsumerGroup(redis) {
    try {
        await redis.xgroup('CREATE', STREAM_KEY, CONSUMER_GROUP, '0', 'MKSTREAM');
    } catch (err) {
        // Group already exists — safe to ignore
        if (!err.message.includes('BUSYGROUP')) throw err;
    }
}

async function processBatch(redis) {
    try {
        const entries = await redis.xreadgroup(
            'GROUP', CONSUMER_GROUP, CONSUMER_NAME,
            'COUNT', BATCH_SIZE,
            'BLOCK', 2000,
            'STREAMS', STREAM_KEY, '>'
        );

        if (!entries || entries.length === 0) return 0;

        const [, messages] = entries[0];
        const writePromises = [];

        for (const [id, fields] of messages) {
            try {
                const event = JSON.parse(fields[1]); // fields = ['data', JSON]
                if (event.type === 'drug_usage') {
                    writePromises.push(updateDrugUsageCounters(event.payload));
                } else if (event.type === 'interaction') {
                    writePromises.push(writeInteractionAnalytics(event.payload));
                }
            } catch (parseErr) {
                logger.error('Failed to parse analytics event', { id, error: parseErr.message });
            }
        }

        // Execute all writes
        const results = await Promise.allSettled(writePromises);
        const failures = results.filter(r => r.status === 'rejected');

        if (failures.length > 0) {
            logger.warn(`${failures.length}/${results.length} analytics writes failed`);
        }

        // Acknowledge processed messages
        const ids = messages.map(([id]) => id);
        await redis.xack(STREAM_KEY, CONSUMER_GROUP, ...ids);

        return messages.length;
    } catch (err) {
        logger.error('Analytics consumer batch error', { error: err.message });
        return 0;
    }
}

async function startConsumer() {
    await connectRedis();
    await connectCassandra();

    const redis = getRedis();
    await ensureConsumerGroup(redis);

    logger.info(`Analytics consumer started (PID: ${process.pid})`);

    const loop = async () => {
        const count = await processBatch(redis);
        if (count > 0) {
            logger.info(`Processed ${count} analytics events`);
        }
        setTimeout(loop, BATCH_INTERVAL_MS);
    };

    loop();

    // Graceful shutdown
    const shutdown = async (signal) => {
        logger.info(`${signal} — shutting down analytics consumer`);
        await shutdownCassandra();
        await disconnectRedis();
        process.exit(0);
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));
}

startConsumer().catch(err => {
    logger.error('Fatal: analytics consumer failed to start', { error: err.message });
    process.exit(1);
});

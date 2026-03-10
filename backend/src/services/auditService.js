/**
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * AUDIT SERVICE — Reliable audit trail with retry queue
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * HIPAA requires a COMPLETE audit trail. This service:
 * 1. Attempts Cassandra write immediately
 * 2. On failure, pushes to a Redis retry queue
 * 3. A background worker flushes the queue
 * 4. After max retries, pushes to dead-letter queue
 * 5. Monitors dead-letter queue size
 * 
 * NEVER silently swallows audit errors.
 */
const { getRedis } = require('./redisService');
const { writeAuditEvent, writeAlertLog, writeInteractionAnalytics, updateDrugUsageCounters } = require('./cassandraService');
const { logger } = require('../middleware/logger');

const AUDIT_RETRY_KEY = 'audit:retry_queue';
const AUDIT_DEAD_LETTER_KEY = 'audit:dead_letter';
const MAX_RETRIES = 3;
const RETRY_BASE_DELAY_MS = 100;

/**
 * Enqueue an audit event with reliable delivery.
 * Tries Cassandra first, falls back to Redis queue on failure.
 */
async function logAuditEvent(event) {
    try {
        await writeAuditEvent(event);
    } catch (err) {
        logger.warn('Cassandra audit write failed, queuing for retry', {
            error: err.message,
            action: event.action,
        });
        await enqueueForRetry('audit_event', event);
    }
}

async function logAlertEvent(event) {
    try {
        await writeAlertLog(event);
    } catch (err) {
        logger.warn('Cassandra alert log write failed, queuing for retry', {
            error: err.message,
        });
        await enqueueForRetry('alert_log', event);
    }
}

async function logAnalytics(event) {
    try {
        await writeInteractionAnalytics(event);
    } catch (err) {
        logger.warn('Cassandra analytics write failed, queuing for retry', {
            error: err.message,
        });
        await enqueueForRetry('analytics', event);
    }
}

async function logDrugUsage(event) {
    try {
        await updateDrugUsageCounters(event);
    } catch (err) {
        logger.warn('Cassandra drug usage write failed, queuing for retry', {
            error: err.message,
        });
        await enqueueForRetry('drug_usage', event);
    }
}

// ─── Retry Queue ──────────────────────────────────────

async function enqueueForRetry(type, event) {
    const redis = getRedis();
    if (!redis) {
        logger.error('CRITICAL: Both Cassandra and Redis unavailable — audit event LOST', {
            type,
            action: event.action || 'unknown',
        });
        return;
    }

    const payload = JSON.stringify({ type, event, retryCount: 0, enqueuedAt: Date.now() });
    await redis.lpush(AUDIT_RETRY_KEY, payload);
}

/**
 * Process the retry queue. Call this on a timer (e.g., every 5s).
 * Returns number of items processed.
 */
async function processRetryQueue() {
    const redis = getRedis();
    if (!redis) return 0;

    let processed = 0;
    const batchSize = 50;

    for (let i = 0; i < batchSize; i++) {
        const raw = await redis.rpop(AUDIT_RETRY_KEY);
        if (!raw) break;

        let item;
        try {
            item = JSON.parse(raw);
        } catch {
            logger.error('Malformed audit retry item', { raw });
            continue;
        }

        try {
            await executeWrite(item.type, item.event);
            processed++;
        } catch (err) {
            item.retryCount++;
            if (item.retryCount >= MAX_RETRIES) {
                logger.error('Audit event moved to dead-letter queue after max retries', {
                    type: item.type,
                    retryCount: item.retryCount,
                });
                await redis.lpush(AUDIT_DEAD_LETTER_KEY, JSON.stringify(item));
            } else {
                // Re-enqueue with incremented retry count
                await redis.lpush(AUDIT_RETRY_KEY, JSON.stringify(item));
            }
        }
    }

    // Monitor dead-letter queue size
    const dlqSize = await redis.llen(AUDIT_DEAD_LETTER_KEY);
    if (dlqSize > 1000) {
        logger.error('ALERT: Audit dead-letter queue exceeds 1000 items', { size: dlqSize });
    }

    return processed;
}

async function executeWrite(type, event) {
    switch (type) {
        case 'audit_event': return writeAuditEvent(event);
        case 'alert_log': return writeAlertLog(event);
        case 'analytics': return writeInteractionAnalytics(event);
        case 'drug_usage': return updateDrugUsageCounters(event);
        default: throw new Error(`Unknown audit type: ${type}`);
    }
}

/**
 * Start the retry queue processor on a 5-second interval.
 */
let _interval = null;
function startRetryProcessor() {
    if (_interval) return;
    _interval = setInterval(async () => {
        try {
            const count = await processRetryQueue();
            if (count > 0) {
                logger.info(`Audit retry queue: processed ${count} items`);
            }
        } catch (err) {
            logger.error('Audit retry processor error', { error: err.message });
        }
    }, 5000);
}

function stopRetryProcessor() {
    if (_interval) {
        clearInterval(_interval);
        _interval = null;
    }
}

module.exports = {
    logAuditEvent,
    logAlertEvent,
    logAnalytics,
    logDrugUsage,
    startRetryProcessor,
    stopRetryProcessor,
    processRetryQueue,
};

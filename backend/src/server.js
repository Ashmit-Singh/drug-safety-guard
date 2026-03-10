require('dotenv').config();

// ─── Validate environment FIRST (fail-fast) ───────────
const { loadConfig } = require('./config/env');
const config = loadConfig();

const app = require('./app');
const { logger } = require('./middleware/logger');
const { connectCassandra, shutdownCassandra } = require('./services/cassandraService');
const { connectRedis, disconnectRedis } = require('./services/redisService');
const { startRetryProcessor, stopRetryProcessor } = require('./services/auditService');

async function startServer() {
    try {
        // Connect to Cassandra (optional — degraded mode if unavailable)
        try {
            await connectCassandra();
            logger.info('Cassandra connected successfully');
        } catch (err) {
            logger.warn(`Cassandra unavailable — running in degraded mode (${err.message})`);
        }

        // Connect to Redis (optional — degraded mode if unavailable)
        try {
            await connectRedis();
            logger.info('Redis connected successfully');
        } catch (err) {
            logger.warn(`Redis unavailable — running without cache (${err.message})`);
        }

        // Start audit retry queue processor
        try {
            startRetryProcessor();
            logger.info('Audit retry processor started (5s interval)');
        } catch (err) {
            logger.warn(`Audit processor skipped (${err.message})`);
        }

        // Start Express server
        const server = app.listen(config.PORT, () => {
            logger.info(`Drug Interaction API running on port ${config.PORT}`);
            logger.info(`Environment: ${config.NODE_ENV}`);
            logger.info(`Health check: http://localhost:${config.PORT}/api/v1/health`);
        });

        // Graceful shutdown
        const gracefulShutdown = async (signal) => {
            logger.info(`${signal} received. Starting graceful shutdown...`);

            // Stop accepting new requests
            server.close(async () => {
                logger.info('HTTP server closed');

                // Stop audit processor
                stopRetryProcessor();
                logger.info('Audit retry processor stopped');

                try {
                    await shutdownCassandra();
                    logger.info('Cassandra disconnected');
                } catch (err) {
                    logger.error('Cassandra disconnect error', { error: err.message });
                }

                try {
                    await disconnectRedis();
                    logger.info('Redis disconnected');
                } catch (err) {
                    logger.error('Redis disconnect error', { error: err.message });
                }

                logger.info('Graceful shutdown complete');
                process.exit(0);
            });

            // Force shutdown after 10 seconds
            setTimeout(() => {
                logger.error('Forced shutdown after timeout');
                process.exit(1);
            }, 10000);
        };

        process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
        process.on('SIGINT', () => gracefulShutdown('SIGINT'));

    } catch (error) {
        logger.error('Failed to start server', { error: error.message });
        process.exit(1);
    }
}

startServer();

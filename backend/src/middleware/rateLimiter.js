/**
 * Redis-backed rate limiting (S-04).
 * Replaces MemoryStore with redis store for horizontal scaling.
 */
const rateLimit = require('express-rate-limit');
const { getConfig } = require('../config/env');

let RedisStore;
try {
    // rate-limit-redis v4 uses named export
    RedisStore = require('rate-limit-redis').default || require('rate-limit-redis');
} catch {
    RedisStore = null;
}

/**
 * Create a rate limiter with Redis store if available,
 * falling back to in-memory store in development.
 */
function createRateLimiter(options = {}) {
    const config = getConfig();
    const { getRedis } = require('../services/redisService');
    const redis = getRedis();

    const limiterOptions = {
        windowMs: options.windowMs || config.RATE_LIMIT_WINDOW_MS,
        max: options.max || config.RATE_LIMIT_MAX,
        standardHeaders: true,
        legacyHeaders: false,
        keyGenerator: (req) => {
            return req.user?.id || req.ip;
        },
        handler: (req, res) => {
            res.status(429).json({
                success: false,
                error: 'Too Many Requests',
                message: 'Rate limit exceeded. Please try again later.',
                code: 'RATE_LIMIT_EXCEEDED',
                meta: {
                    requestId: req.requestId,
                    timestamp: new Date().toISOString(),
                },
            });
        },
    };

    // Use Redis store if available (required for multi-instance deployments)
    if (redis && RedisStore) {
        limiterOptions.store = new RedisStore({
            sendCommand: (...args) => redis.call(...args),
            prefix: options.prefix || 'rl:',
        });
    }

    return rateLimit(limiterOptions);
}

const generalLimiter = createRateLimiter({
    prefix: 'rl:general:',
    max: process.env.NODE_ENV === 'development' ? 10000 : undefined,
});

const interactionCheckLimiter = createRateLimiter({
    windowMs: 60000,
    max: 10,
    prefix: 'rl:interaction:',
});

const authLimiter = createRateLimiter({
    windowMs: 900000, // 15 min
    max: 5,
    prefix: 'rl:auth:',
});

module.exports = { generalLimiter, interactionCheckLimiter, authLimiter, createRateLimiter };

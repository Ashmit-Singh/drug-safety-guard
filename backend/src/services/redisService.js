const Redis = require('ioredis');
const { logger } = require('../middleware/logger');

let redis = null;

async function connectRedis() {
    redis = new Redis(process.env.REDIS_URL || 'redis://127.0.0.1:6379', {
        password: process.env.REDIS_PASSWORD || undefined,
        maxRetriesPerRequest: 3,
        retryStrategy(times) {
            const delay = Math.min(times * 50, 2000);
            return delay;
        },
        lazyConnect: false,
    });

    redis.on('error', (err) => {
        logger.error('Redis connection error', { error: err.message });
    });

    redis.on('connect', () => {
        logger.debug('Redis connected');
    });

    return redis;
}

async function disconnectRedis() {
    if (redis) {
        await redis.quit();
        redis = null;
    }
}

function getRedis() {
    return redis;
}

// ─── Interaction Cache Helpers ────────────────────────

const INTERACTION_CACHE_TTL = 86400; // 24 hours
const INTERACTION_PREFIX = 'ingredient_pair';

function makeInteractionCacheKey(ingredientAId, ingredientBId) {
    // Canonical order: smaller UUID first
    const [first, second] = ingredientAId < ingredientBId
        ? [ingredientAId, ingredientBId]
        : [ingredientBId, ingredientAId];
    return `${INTERACTION_PREFIX}:${first}:${second}`;
}

async function getCachedInteraction(ingredientAId, ingredientBId) {
    if (!redis) return null;
    try {
        const key = makeInteractionCacheKey(ingredientAId, ingredientBId);
        const cached = await redis.get(key);
        if (cached) {
            return JSON.parse(cached);
        }
        return null;
    } catch (err) {
        logger.error('Redis cache get error', { error: err.message });
        return null;
    }
}

async function setCachedInteraction(ingredientAId, ingredientBId, interaction) {
    if (!redis) return;
    try {
        const key = makeInteractionCacheKey(ingredientAId, ingredientBId);
        await redis.setex(key, INTERACTION_CACHE_TTL, JSON.stringify(interaction));
    } catch (err) {
        logger.error('Redis cache set error', { error: err.message });
    }
}

async function invalidateInteractionCache(ingredientAId, ingredientBId) {
    if (!redis) return;
    try {
        const key = makeInteractionCacheKey(ingredientAId, ingredientBId);
        await redis.del(key);
    } catch (err) {
        logger.error('Redis cache delete error', { error: err.message });
    }
}

/**
 * Batch lookup of ingredient interactions using Redis pipeline.
 * Single round-trip instead of N sequential GET calls.
 * @param {Array<[string, string]>} pairs - Array of [ingredientAId, ingredientBId] pairs
 * @returns {Map<string, object>} Map of "id_a:id_b" → interaction object
 */
async function batchGetCachedInteractions(pairs) {
    const resultMap = new Map();
    if (!redis || pairs.length === 0) return resultMap;

    try {
        const pipeline = redis.pipeline();
        const keys = [];
        for (const [a, b] of pairs) {
            const key = makeInteractionCacheKey(a, b);
            keys.push(key);
            pipeline.get(key);
        }

        const results = await pipeline.exec();

        for (let i = 0; i < results.length; i++) {
            const [err, val] = results[i];
            if (!err && val) {
                const [a, b] = pairs[i];
                const canonKey = a < b ? `${a}:${b}` : `${b}:${a}`;
                resultMap.set(canonKey, JSON.parse(val));
            }
        }
    } catch (err) {
        logger.error('Redis batch get error', { error: err.message });
    }

    return resultMap;
}

async function getCachedData(key) {
    if (!redis) return null;
    try {
        const data = await redis.get(key);
        return data ? JSON.parse(data) : null;
    } catch (err) {
        logger.error('Redis get error', { error: err.message });
        return null;
    }
}

async function setCachedData(key, data, ttlSeconds = 300) {
    if (!redis) return;
    try {
        await redis.setex(key, ttlSeconds, JSON.stringify(data));
    } catch (err) {
        logger.error('Redis set error', { error: err.message });
    }
}

async function deleteCachedData(key) {
    if (!redis) return;
    try {
        await redis.del(key);
    } catch (err) {
        logger.error('Redis del error', { error: err.message });
    }
}

module.exports = {
    connectRedis,
    disconnectRedis,
    getRedis,
    getCachedInteraction,
    setCachedInteraction,
    invalidateInteractionCache,
    batchGetCachedInteractions,
    getCachedData,
    setCachedData,
    deleteCachedData,
};

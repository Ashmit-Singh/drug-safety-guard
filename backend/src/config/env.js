/**
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * ENVIRONMENT CONFIGURATION
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * Validates ALL required environment variables at startup.
 * If any are missing or malformed, the process throws
 * immediately with a clear error — never boots in a broken state.
 */
const { z } = require('zod');

const envSchema = z.object({
    // Server
    NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
    PORT: z.coerce.number().int().min(1).max(65535).default(3000),

    // Supabase
    SUPABASE_URL: z.string().url(),
    SUPABASE_ANON_KEY: z.string().min(10),
    SUPABASE_SERVICE_KEY: z.string().min(10),

    // JWT
    JWT_SECRET: z.string().min(32, 'JWT_SECRET must be at least 32 characters'),

    // Redis
    REDIS_URL: z.string().default('redis://127.0.0.1:6379'),
    REDIS_PASSWORD: z.string().optional(),

    // Cassandra
    CASSANDRA_HOSTS: z.string().default('127.0.0.1'),
    CASSANDRA_DATACENTER: z.string().default('dc1'),
    CASSANDRA_KEYSPACE: z.string().default('drug_interaction_analytics'),
    CASSANDRA_PORT: z.coerce.number().default(9042),
    CASSANDRA_USERNAME: z.string().optional(),
    CASSANDRA_PASSWORD: z.string().optional(),

    // Rate Limiting
    RATE_LIMIT_WINDOW_MS: z.coerce.number().default(60000),
    RATE_LIMIT_MAX: z.coerce.number().default(1000),        // generous for dev
    INTERACTION_CHECK_RATE_LIMIT_MAX: z.coerce.number().default(50),

    // CORS
    FLUTTER_WEB_ORIGIN: z.string().default('http://localhost:8080'),

    // Audit Queue
    AUDIT_QUEUE_MAX_RETRIES: z.coerce.number().default(3),
    AUDIT_DEAD_LETTER_THRESHOLD: z.coerce.number().default(1000),
});

let _config;

function loadConfig() {
    const result = envSchema.safeParse(process.env);
    if (!result.success) {
        const formatted = result.error.issues
            .map(i => `  • ${i.path.join('.')}: ${i.message}`)
            .join('\n');
        console.error(`\n❌ Environment validation failed:\n${formatted}\n`);
        process.exit(1);
    }
    _config = Object.freeze(result.data);
    return _config;
}

function getConfig() {
    if (!_config) return loadConfig();
    return _config;
}

module.exports = { loadConfig, getConfig };

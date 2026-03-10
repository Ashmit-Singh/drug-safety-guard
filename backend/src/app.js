const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { v4: uuidv4 } = require('uuid');
const { errorHandler } = require('./middleware/errorHandler');
const { requestLogger } = require('./middleware/logger');
const { generalLimiter } = require('./middleware/rateLimiter');
const { getConfig } = require('./config/env');
const { sendError } = require('./utils/response');

// Versioned route bundles
const v1Routes = require('./routes/v1/index');
const v2Routes = require('./routes/v2/index');

const app = express();
const config = getConfig();

// ─── Security Middleware ───────────────────────────────
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            imgSrc: ["'self'", 'data:', 'https:'],
        },
    },
    crossOriginEmbedderPolicy: false,
}));

app.use(cors({
    origin: config.NODE_ENV === 'development'
        ? '*'   // Allow all origins in dev (Flutter uses random ports)
        : [
            config.FLUTTER_WEB_ORIGIN,
            'https://drug-safety.yourdomain.com',
        ],
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-Id'],
    credentials: config.NODE_ENV !== 'development',   // credentials incompatible with origin:'*'
    maxAge: 86400,
}));

// ─── Body Parsing ─────────────────────────────────────
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true, limit: '10kb' }));

// ─── Request ID (distributed tracing) ─────────────────
app.use((req, res, next) => {
    req.requestId = req.headers['x-request-id'] || uuidv4();
    res.setHeader('X-Request-Id', req.requestId);
    next();
});

// ─── Logging & Rate Limiting ──────────────────────────
app.use(requestLogger);
app.use(generalLimiter);

// ─── Health Check (no auth required) ──────────────────
const { getRedis } = require('./services/redisService');
const { getClient: getCassandraClient } = require('./services/cassandraService');
const { supabase } = require('./middleware/auth');

app.get('/api/v1/health', async (req, res) => {
    const redis = getRedis();
    const cassandra = getCassandraClient();

    const [redisOk, cassandraOk, supabaseOk] = await Promise.all([
        redis ? redis.ping().then(() => true).catch(() => false) : Promise.resolve(false),
        cassandra ? cassandra.execute('SELECT now() FROM system.local').then(() => true).catch(() => false) : Promise.resolve(false),
        supabase.from('drugs').select('id').limit(1).then(() => true).catch(() => false),
    ]);

    const allHealthy = redisOk && cassandraOk && supabaseOk;
    const anyHealthy = redisOk || cassandraOk || supabaseOk;

    let status, statusCode;
    if (allHealthy) { status = 'healthy'; statusCode = 200; }
    else if (anyHealthy) { status = 'degraded'; statusCode = 207; }
    else { status = 'unhealthy'; statusCode = 503; }

    res.status(statusCode).json({
        success: true,
        data: {
            status,
            timestamp: new Date().toISOString(),
            version: '1.0.0',
            uptime: process.uptime(),
            dependencies: {
                redis: redisOk ? 'connected' : 'disconnected',
                cassandra: cassandraOk ? 'connected' : 'disconnected',
                supabase: supabaseOk ? 'connected' : 'disconnected',
            },
        },
    });
});

// ─── API Routes (versioned) ───────────────────────────
app.use('/api/v1', v1Routes);
app.use('/api/v2', v2Routes);

// ─── 404 Handler ──────────────────────────────────────
app.use((req, res) => {
    sendError(res, {
        statusCode: 404,
        error: 'Not Found',
        message: `Route ${req.method} ${req.originalUrl} not found`,
        code: 'ROUTE_NOT_FOUND',
    });
});

// ─── Global Error Handler ─────────────────────────────
app.use(errorHandler);

module.exports = app;

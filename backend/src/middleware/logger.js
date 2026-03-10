const winston = require('winston');
const { writeAuditEvent } = require('../services/cassandraService');

const logger = winston.createLogger({
    level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
    format: winston.format.combine(
        winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    defaultMeta: { service: 'drug-interaction-api' },
    transports: [
        new winston.transports.Console({
            format: winston.format.combine(
                winston.format.colorize(),
                winston.format.printf(({ timestamp, level, message, ...meta }) => {
                    const metaStr = Object.keys(meta).length > 1
                        ? ` ${JSON.stringify(meta)}` : '';
                    return `${timestamp} [${level}]: ${message}${metaStr}`;
                })
            ),
        }),
    ],
});

// Add file transport in production
if (process.env.NODE_ENV === 'production') {
    logger.add(new winston.transports.File({
        filename: 'logs/error.log',
        level: 'error',
        maxsize: 5242880, // 5MB
        maxFiles: 5,
    }));
    logger.add(new winston.transports.File({
        filename: 'logs/combined.log',
        maxsize: 5242880,
        maxFiles: 5,
    }));
}

// Request logger middleware
function requestLogger(req, res, next) {
    const start = Date.now();

    // Capture response finish
    res.on('finish', () => {
        const duration = Date.now() - start;
        const logData = {
            method: req.method,
            path: req.originalUrl,
            statusCode: res.statusCode,
            duration: `${duration}ms`,
            ip: req.ip,
            userAgent: req.get('User-Agent'),
            userId: req.user?.id,
        };

        if (res.statusCode >= 400) {
            logger.warn('Request completed with error', logData);
        } else {
            logger.info('Request completed', logData);
        }

        // Async audit event write to Cassandra (non-blocking, fire-and-forget)
        if (req.user && isAuditableRequest(req)) {
            writeAuditEvent({
                userId: req.user.id,
                userEmail: req.user.email,
                userRole: req.user.role,
                action: `${req.method} ${req.route?.path || req.originalUrl}`,
                resourceType: extractResourceType(req.originalUrl),
                resourceId: req.params?.id || null,
                details: JSON.stringify({
                    query: req.query,
                    statusCode: res.statusCode,
                }),
                ipAddress: req.ip,
                userAgent: req.get('User-Agent'),
                requestMethod: req.method,
                requestPath: req.originalUrl,
                responseStatus: res.statusCode,
                durationMs: duration,
            }).catch(err => {
                logger.error('Failed to write audit event', { error: err.message });
            });
        }
    });

    next();
}

function isAuditableRequest(req) {
    // Audit all state-changing requests and patient data access
    if (['POST', 'PUT', 'DELETE', 'PATCH'].includes(req.method)) return true;
    if (req.originalUrl.includes('/patients')) return true;
    if (req.originalUrl.includes('/prescriptions')) return true;
    if (req.originalUrl.includes('/alerts')) return true;
    return false;
}

function extractResourceType(url) {
    const segments = url.split('/').filter(Boolean);
    // /api/v1/patients/:id -> 'patients'
    return segments[2] || 'unknown';
}

module.exports = { logger, requestLogger };

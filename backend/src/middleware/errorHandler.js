const { logger } = require('./logger');

class AppError extends Error {
    constructor(statusCode, message, code) {
        super(message);
        this.statusCode = statusCode;
        this.code = code;
        this.isOperational = true;
        Error.captureStackTrace(this, this.constructor);
    }
}

class BadRequestError extends AppError {
    constructor(message = 'Bad Request', code = 'BAD_REQUEST') {
        super(400, message, code);
    }
}

class UnauthorizedError extends AppError {
    constructor(message = 'Unauthorized', code = 'UNAUTHORIZED') {
        super(401, message, code);
    }
}

class ForbiddenError extends AppError {
    constructor(message = 'Forbidden', code = 'FORBIDDEN') {
        super(403, message, code);
    }
}

class NotFoundError extends AppError {
    constructor(message = 'Not Found', code = 'NOT_FOUND') {
        super(404, message, code);
    }
}

class ConflictError extends AppError {
    constructor(message = 'Conflict', code = 'CONFLICT') {
        super(409, message, code);
    }
}

function errorHandler(err, req, res, _next) {
    // Centralized validation errors (from validate() middleware)
    if (err.name === 'ValidationError') {
        return res.status(err.statusCode || 422).json({
            success: false,
            error: 'Validation Error',
            message: err.message,
            code: err.code || 'VALIDATION_ERROR',
            details: err.details || [],
            meta: {
                requestId: req.requestId || null,
                timestamp: new Date().toISOString(),
            },
        });
    }

    // Zod validation errors (legacy inline .parse() calls)
    if (err.name === 'ZodError') {
        return res.status(400).json({
            success: false,
            error: 'Validation Error',
            message: 'Invalid input data',
            code: 'VALIDATION_ERROR',
            details: err.errors.map(e => ({
                field: e.path.join('.'),
                message: e.message,
            })),
            meta: {
                requestId: req.requestId || null,
                timestamp: new Date().toISOString(),
            },
        });
    }

    // Operational errors (our custom errors)
    if (err instanceof AppError) {
        return res.status(err.statusCode).json({
            error: err.message,
            message: err.message,
            code: err.code,
        });
    }

    // Supabase errors
    if (err.code && err.message && err.details) {
        logger.error('Supabase error', {
            code: err.code,
            message: err.message,
            details: err.details,
        });
        return res.status(500).json({
            error: 'Database Error',
            message: 'A database error occurred. Please try again.',
            code: 'DATABASE_ERROR',
        });
    }

    // Unknown errors — log full details but don't expose to client
    logger.error('Unhandled error', {
        error: err.message,
        stack: err.stack,
        path: req.originalUrl,
        method: req.method,
    });

    return res.status(500).json({
        error: 'Internal Server Error',
        message: 'An unexpected error occurred. Please try again later.',
        code: 'INTERNAL_ERROR',
    });
}

module.exports = {
    AppError,
    BadRequestError,
    UnauthorizedError,
    ForbiddenError,
    NotFoundError,
    ConflictError,
    errorHandler,
};

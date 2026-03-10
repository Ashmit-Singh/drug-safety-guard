/**
 * Standardized API response helpers.
 * All responses follow the envelope: { success, data, meta, pagination, _links }
 * Fixes API-02 (inconsistent response shapes).
 */

function sendSuccess(res, data, { statusCode = 200, links = null } = {}) {
    const body = {
        success: true,
        data,
        meta: {
            requestId: res.req?.requestId || null,
            timestamp: new Date().toISOString(),
        },
        pagination: null,
    };
    if (links) body._links = links;
    return res.status(statusCode).json(body);
}

function sendPaginated(res, data, { total, limit, offset, nextCursor = null, links = null } = {}) {
    const body = {
        success: true,
        data,
        meta: {
            requestId: res.req?.requestId || null,
            timestamp: new Date().toISOString(),
        },
        pagination: {
            total,
            limit,
            offset,
            nextCursor,
            hasMore: nextCursor !== null || (offset + limit < total),
        },
    };
    if (links) body._links = links;
    return res.status(200).json(body);
}

function sendError(res, { statusCode = 500, error = 'Error', message, code, details = null }) {
    return res.status(statusCode).json({
        success: false,
        error,
        message,
        code,
        details,
        meta: {
            requestId: res.req?.requestId || null,
            timestamp: new Date().toISOString(),
        },
    });
}

function sendMessage(res, message, { statusCode = 200, data = null } = {}) {
    return res.status(statusCode).json({
        success: true,
        message,
        data,
        meta: {
            requestId: res.req?.requestId || null,
            timestamp: new Date().toISOString(),
        },
    });
}

module.exports = { sendSuccess, sendPaginated, sendError, sendMessage };

/**
 * Input sanitization middleware.
 * Strips HTML/XSS from specified string fields AFTER Zod validation.
 * Uses the 'xss' package (lightweight, no jsdom dependency).
 * 
 * Usage:
 *   router.post('/foo',
 *     validate(schema),
 *     sanitize(['diagnosis', 'notes', 'instructions']),
 *     controller.handleFoo
 *   );
 */
const xss = require('xss');

const xssOptions = {
    whiteList: {},          // No HTML tags allowed
    stripIgnoreTag: true,   // Remove all unknown tags
    stripIgnoreTagBody: ['script', 'style'],
};

function sanitize(fields = []) {
    return (req, _res, next) => {
        if (!req.validated) {
            return next();
        }

        for (const field of fields) {
            if (typeof req.validated[field] === 'string') {
                req.validated[field] = xss(req.validated[field], xssOptions);
            }
        }

        next();
    };
}

/**
 * Deep sanitize all string values in an object.
 * Use for objects with unknown structure (e.g., JSONB fields).
 */
function deepSanitize(obj) {
    if (typeof obj === 'string') return xss(obj, xssOptions);
    if (Array.isArray(obj)) return obj.map(deepSanitize);
    if (obj && typeof obj === 'object') {
        const result = {};
        for (const [key, value] of Object.entries(obj)) {
            result[key] = deepSanitize(value);
        }
        return result;
    }
    return obj;
}

module.exports = { sanitize, deepSanitize };

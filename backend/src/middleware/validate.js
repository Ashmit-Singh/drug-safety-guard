/**
 * Centralized Zod validation middleware.
 * Accepts a Zod schema and validates req.body (or req.query/req.params).
 * On failure: passes a structured 422 error to next().
 * 
 * Usage:
 *   router.post('/foo', validate(mySchema), controller.handleFoo);
 *   router.get('/foo', validate(querySchema, 'query'), controller.listFoo);
 */

function validate(schema, source = 'body') {
    return (req, _res, next) => {
        const data = source === 'body' ? req.body
            : source === 'query' ? req.query
            : source === 'params' ? req.params
            : req.body;

        const result = schema.safeParse(data);

        if (!result.success) {
            const err = new Error('Validation failed');
            err.name = 'ValidationError';
            err.statusCode = 422;
            err.code = 'VALIDATION_ERROR';
            err.details = result.error.issues.map(issue => ({
                field: issue.path.join('.'),
                message: issue.message,
                code: issue.code,
            }));
            return next(err);
        }

        // Attach validated data to request for downstream use
        req.validated = result.data;
        next();
    };
}

module.exports = { validate };

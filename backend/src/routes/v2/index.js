/**
 * V2 Route Stub
 * 
 * API v2 placeholder. v2 routes will use:
 * - Keyset pagination (cursor-based) instead of offset
 * - Standardized HATEOAS links on all resources
 * - Breaking changes that cannot be made to v1
 * 
 * See docs/API_VERSIONING.md for the migration strategy.
 */
const express = require('express');
const router = express.Router();

router.get('/health', (req, res) => {
    res.json({
        success: true,
        data: {
            version: '2.0.0-stub',
            status: 'not_implemented',
            message: 'API v2 is under development. Use /api/v1 for production.',
        },
    });
});

module.exports = router;

/**
 * CSRF Protection — Double Submit Cookie Strategy
 * 
 * How it works:
 * 1. Server sets a random token in a CSRF cookie (SameSite=Strict)
 * 2. Client reads the cookie and sends it back in X-CSRF-Token header
 * 3. Server verifies cookie and header match
 * 
 * This works for Flutter Web because:
 * - Flutter Web (via dart:html) can read cookies on the same domain
 * - Mobile Flutter apps don't need CSRF (no cookies = no CSRF risk)
 */
const crypto = require('crypto');

const CSRF_COOKIE_NAME = '__csrf_token';
const CSRF_HEADER_NAME = 'x-csrf-token';

function generateCsrfToken() {
    return crypto.randomBytes(32).toString('hex');
}

function csrfProtection(options = {}) {
    const { exempt = ['/api/v1/health', '/.well-known/jwks.json'] } = options;

    return (req, res, next) => {
        // Skip for safe methods
        if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) {
            // Set CSRF cookie on GET requests so client can read it
            if (!req.cookies?.[CSRF_COOKIE_NAME]) {
                const token = generateCsrfToken();
                res.cookie(CSRF_COOKIE_NAME, token, {
                    httpOnly: false,             // Client must read this
                    secure: process.env.NODE_ENV === 'production',
                    sameSite: 'Strict',
                    maxAge: 3600000,             // 1 hour
                    path: '/',
                });
            }
            return next();
        }

        // Skip exempt paths
        if (exempt.some(path => req.path.startsWith(path))) {
            return next();
        }

        // Verify CSRF for state-changing requests (POST, PUT, DELETE)
        const cookieToken = req.cookies?.[CSRF_COOKIE_NAME];
        const headerToken = req.headers[CSRF_HEADER_NAME];

        if (!cookieToken || !headerToken) {
            return res.status(403).json({
                success: false,
                error: 'Forbidden',
                message: 'CSRF token missing',
                code: 'CSRF_TOKEN_MISSING',
            });
        }

        // Constant-time comparison to prevent timing attacks
        const cookieBuf = Buffer.from(cookieToken, 'utf8');
        const headerBuf = Buffer.from(headerToken, 'utf8');

        if (cookieBuf.length !== headerBuf.length || !crypto.timingSafeEqual(cookieBuf, headerBuf)) {
            return res.status(403).json({
                success: false,
                error: 'Forbidden',
                message: 'CSRF token mismatch',
                code: 'CSRF_TOKEN_INVALID',
            });
        }

        // Rotate token after successful verification
        const newToken = generateCsrfToken();
        res.cookie(CSRF_COOKIE_NAME, newToken, {
            httpOnly: false,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'Strict',
            maxAge: 3600000,
            path: '/',
        });

        next();
    };
}

module.exports = { csrfProtection, CSRF_COOKIE_NAME, CSRF_HEADER_NAME };

const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY
);

const supabaseAnon = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY
);

async function authGuard(req, res, next) {
    // ─── DEV BYPASS: Skip auth in development mode ────────────
    if (process.env.NODE_ENV === 'development') {
        req.user = {
            id: 'de000000-0000-4000-a000-000000000001',
            authId: 'de000000-0000-4000-a000-000000000002',
            email: 'admin@drugsafety.dev',
            fullName: 'Dev Admin',
            role: 'admin',
        };
        return next();
    }
    // ──────────────────────────────────────────────────────────

    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'Missing or invalid Authorization header. Expected: Bearer <token>',
                code: 'AUTH_MISSING_TOKEN',
            });
        }

        const token = authHeader.split(' ')[1];

        // Validate token via Supabase Auth (no custom JWT_SECRET needed)
        const { data: { user }, error } = await supabase.auth.admin.getUserById(
            // First decode the token to get the sub (user id)
            (() => {
                try {
                    const payload = JSON.parse(
                        Buffer.from(token.split('.')[1], 'base64').toString()
                    );
                    return payload.sub;
                } catch {
                    return null;
                }
            })()
        );

        if (error || !user) {
            // Fallback: try getUser with the token directly
            const { data: tokenData, error: tokenError } = await supabase.auth.getUser(token);
            if (tokenError || !tokenData?.user) {
                return res.status(401).json({
                    error: 'Unauthorized',
                    message: 'Invalid or expired token.',
                    code: 'AUTH_INVALID_TOKEN',
                });
            }
            // Use the user from token validation
            var authUser = tokenData.user;
        } else {
            var authUser = user;
        }

        // Fetch app-level user profile with role
        const { data: appUser, error: profileError } = await supabase
            .from('users')
            .select('id, email, full_name, role, is_active')
            .eq('auth_id', authUser.id)
            .is('deleted_at', null)
            .single();

        if (profileError || !appUser) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User profile not found. Please contact admin.',
                code: 'AUTH_PROFILE_NOT_FOUND',
            });
        }

        if (!appUser.is_active) {
            return res.status(403).json({
                error: 'Forbidden',
                message: 'Account has been deactivated.',
                code: 'AUTH_ACCOUNT_DEACTIVATED',
            });
        }

        // Attach user to request
        req.user = {
            id: appUser.id,
            authId: authUser.id,
            email: appUser.email,
            fullName: appUser.full_name,
            role: appUser.role,
        };

        next();
    } catch (error) {
        console.error('Auth error:', error.message);
        return res.status(500).json({
            error: 'Internal Server Error',
            message: 'Authentication service unavailable.',
            code: 'AUTH_SERVICE_ERROR',
        });
    }
}

module.exports = { authGuard, supabase, supabaseAnon };


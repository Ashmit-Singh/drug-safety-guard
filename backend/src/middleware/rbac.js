function rbacGuard(...allowedRoles) {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'Authentication required before role check.',
                code: 'RBAC_NO_USER',
            });
        }

        if (!allowedRoles.includes(req.user.role)) {
            return res.status(403).json({
                error: 'Forbidden',
                message: 'You do not have sufficient permissions to access this resource.',
                code: 'RBAC_INSUFFICIENT_ROLE',
            });
        }

        next();
    };
}

// Convenience guards for common role combinations
const doctorOrAdmin = rbacGuard('doctor', 'admin');
const adminOnly = rbacGuard('admin');
const allRoles = rbacGuard('patient', 'doctor', 'admin', 'pharmacist');
const clinicalStaff = rbacGuard('doctor', 'admin', 'pharmacist');

module.exports = { rbacGuard, doctorOrAdmin, adminOnly, allRoles, clinicalStaff };

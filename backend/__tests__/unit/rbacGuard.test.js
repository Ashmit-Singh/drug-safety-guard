/**
 * Unit tests for RBAC guard middleware.
 */

const { rbacGuard } = require('../../src/middleware/rbac');

describe('rbacGuard', () => {
    let req, res, next;

    beforeEach(() => {
        req = { user: { role: 'doctor' } };
        res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn().mockReturnThis(),
        };
        next = jest.fn();
    });

    test('allows doctor when doctor is in allowed roles', () => {
        const guard = rbacGuard('doctor', 'admin');
        guard(req, res, next);
        expect(next).toHaveBeenCalled();
        expect(res.status).not.toHaveBeenCalled();
    });

    test('allows admin when admin is in allowed roles', () => {
        req.user.role = 'admin';
        const guard = rbacGuard('doctor', 'admin');
        guard(req, res, next);
        expect(next).toHaveBeenCalled();
    });

    test('denies patient when only doctor/admin allowed', () => {
        req.user.role = 'patient';
        const guard = rbacGuard('doctor', 'admin');
        guard(req, res, next);
        expect(next).not.toHaveBeenCalled();
        expect(res.status).toHaveBeenCalledWith(403);
    });

    test('error message does NOT leak allowed roles (S-05)', () => {
        req.user.role = 'patient';
        const guard = rbacGuard('doctor', 'admin');
        guard(req, res, next);
        const response = res.json.mock.calls[0][0];
        expect(response.message).not.toContain('doctor');
        expect(response.message).not.toContain('admin');
        expect(response.message).not.toContain('patient');
        expect(response.code).toBe('RBAC_INSUFFICIENT_ROLE');
    });

    test('denies when no user on request', () => {
        delete req.user;
        const guard = rbacGuard('doctor');
        guard(req, res, next);
        expect(next).not.toHaveBeenCalled();
        expect(res.status).toHaveBeenCalledWith(401);
    });

    test('allows single role matches', () => {
        req.user.role = 'pharmacist';
        const guard = rbacGuard('pharmacist');
        guard(req, res, next);
        expect(next).toHaveBeenCalled();
    });
});

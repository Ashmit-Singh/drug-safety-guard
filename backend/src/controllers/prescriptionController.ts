/**
 * PRESCRIPTION CONTROLLER (TypeScript)
 * Thin HTTP handler — zero business logic.
 */
import { Response, NextFunction } from 'express';
import * as prescriptionService from '../services/prescriptionService';
import { sendSuccess, sendPaginated } from '../utils/response';
import { AuthenticatedRequest } from '../types';

export async function create(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
        const data = await prescriptionService.createPrescription(req.validated as any, req.user);
        const links = {
            self: `/api/v1/prescriptions/${data.id}`,
            drugs: `/api/v1/prescriptions/${data.id}/drugs`,
            safetyCheck: `/api/v1/prescriptions/${data.id}/safety-check`,
        };
        sendSuccess(res, data, { statusCode: 201, links } as any);
    } catch (err) {
        next(err);
    }
}

export async function getById(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
        const data = await prescriptionService.getPrescription(req.params.id);
        const links = {
            self: `/api/v1/prescriptions/${data.id}`,
            drugs: `/api/v1/prescriptions/${data.id}/drugs`,
            alerts: `/api/v1/prescriptions/${data.id}/alerts`,
            safetyCheck: `/api/v1/prescriptions/${data.id}/safety-check`,
        };
        sendSuccess(res, data, { links } as any);
    } catch (err) {
        next(err);
    }
}

export async function addDrug(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
        const data = await prescriptionService.addDrug(req.params.id, req.validated as any, req.user);
        const links = {
            prescription: `/api/v1/prescriptions/${req.params.id}`,
            safetyCheck: `/api/v1/prescriptions/${req.params.id}/safety-check`,
        };
        sendSuccess(res, data, { statusCode: 201, links } as any);
    } catch (err) {
        next(err);
    }
}

export async function removeDrug(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
        const data = await prescriptionService.removeDrug(req.params.id, req.params.drugId, req.user);
        sendSuccess(res, data, { statusCode: 200 });
    } catch (err) {
        next(err);
    }
}

export async function safetyCheck(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
        const data = await prescriptionService.safetyCheck(req.params.id);
        sendSuccess(res, data);
    } catch (err) {
        next(err);
    }
}

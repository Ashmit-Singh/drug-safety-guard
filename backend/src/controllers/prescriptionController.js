/**
 * PRESCRIPTION CONTROLLER — HTTP handling only.
 * Parses request, calls prescriptionService, sends standardized response.
 * Zero business logic.
 */
const prescriptionService = require('../services/prescriptionService');
const { sendSuccess, sendPaginated } = require('../utils/response');

async function create(req, res, next) {
    try {
        const data = await prescriptionService.createPrescription(req.validated, req.user);
        const links = {
            self: `/api/v1/prescriptions/${data.id}`,
            drugs: `/api/v1/prescriptions/${data.id}/drugs`,
            safetyCheck: `/api/v1/prescriptions/${data.id}/safety-check`,
        };
        sendSuccess(res, data, { statusCode: 201, links });
    } catch (err) {
        next(err);
    }
}

async function getById(req, res, next) {
    try {
        const data = await prescriptionService.getPrescription(req.params.id);
        const links = {
            self: `/api/v1/prescriptions/${data.id}`,
            drugs: `/api/v1/prescriptions/${data.id}/drugs`,
            alerts: `/api/v1/prescriptions/${data.id}/alerts`,
            safetyCheck: `/api/v1/prescriptions/${data.id}/safety-check`,
        };
        sendSuccess(res, data, { links });
    } catch (err) {
        next(err);
    }
}

async function addDrug(req, res, next) {
    try {
        const data = await prescriptionService.addDrug(req.params.id, req.validated, req.user);
        const links = {
            prescription: `/api/v1/prescriptions/${req.params.id}`,
            safetyCheck: `/api/v1/prescriptions/${req.params.id}/safety-check`,
        };
        sendSuccess(res, data, { statusCode: 201, links });
    } catch (err) {
        next(err);
    }
}

async function removeDrug(req, res, next) {
    try {
        const data = await prescriptionService.removeDrug(req.params.id, req.params.drugId, req.user);
        sendSuccess(res, data, { statusCode: 200 });
    } catch (err) {
        next(err);
    }
}

async function safetyCheck(req, res, next) {
    try {
        const data = await prescriptionService.safetyCheck(req.params.id);
        sendSuccess(res, data);
    } catch (err) {
        next(err);
    }
}

module.exports = { create, getById, addDrug, removeDrug, safetyCheck };

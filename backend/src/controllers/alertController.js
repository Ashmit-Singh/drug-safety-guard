/**
 * ALERT CONTROLLER — HTTP handling only.
 */
const alertService = require('../services/alertService');
const { sendSuccess, sendPaginated, sendMessage } = require('../utils/response');

async function list(req, res, next) {
    try {
        const { data, total } = await alertService.listAlerts(req.validated);
        sendPaginated(res, data, {
            total,
            limit: req.validated.limit,
            offset: req.validated.offset,
        });
    } catch (err) {
        next(err);
    }
}

async function getById(req, res, next) {
    try {
        const data = await alertService.getAlert(req.params.id);
        const links = {
            self: `/api/v1/alerts/${data.id}`,
            acknowledge: `/api/v1/alerts/${data.id}/acknowledge`,
            prescription: `/api/v1/prescriptions/${data.prescription_id}`,
        };
        sendSuccess(res, data, { links });
    } catch (err) {
        next(err);
    }
}

async function acknowledge(req, res, next) {
    try {
        const data = await alertService.acknowledgeAlert(
            req.params.id,
            req.user,
            req.validated?.overrideReason
        );
        sendMessage(res, 'Alert acknowledged', { data });
    } catch (err) {
        next(err);
    }
}

async function batchAcknowledge(req, res, next) {
    try {
        const data = await alertService.batchAcknowledgeAlerts(
            req.validated.alertIds,
            req.user,
            req.validated.overrideReason
        );
        sendMessage(res, `${data.length} alerts acknowledged`, { data });
    } catch (err) {
        next(err);
    }
}

async function getPatientAlerts(req, res, next) {
    try {
        const { data, total } = await alertService.getPatientAlerts(
            req.params.patientId,
            req.validated
        );
        sendPaginated(res, data, {
            total,
            limit: req.validated.limit,
            offset: req.validated.offset,
        });
    } catch (err) {
        next(err);
    }
}

module.exports = { list, getById, acknowledge, batchAcknowledge, getPatientAlerts };

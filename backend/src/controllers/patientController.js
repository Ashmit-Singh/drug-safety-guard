/**
 * PATIENT CONTROLLER — HTTP handling for patient endpoints.
 */
const patientRepo = require('../repositories/patientRepo');
const prescriptionRepo = require('../repositories/prescriptionRepo');
const { sendSuccess, sendPaginated } = require('../utils/response');
const { NotFoundError } = require('../middleware/errorHandler');

async function list(req, res, next) {
    try {
        const { data, total } = await patientRepo.findAll(req.validated);
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
        const data = await patientRepo.findById(req.params.id);
        if (!data) throw new NotFoundError('Patient not found');
        const links = {
            self: `/api/v1/patients/${data.id}`,
            prescriptions: `/api/v1/patients/${data.id}/prescriptions`,
            alerts: `/api/v1/patients/${data.id}/alerts`,
        };
        sendSuccess(res, data, { links });
    } catch (err) {
        next(err);
    }
}

async function create(req, res, next) {
    try {
        const data = await patientRepo.create(req.validated);
        sendSuccess(res, data, { statusCode: 201 });
    } catch (err) {
        next(err);
    }
}

async function getPrescriptions(req, res, next) {
    try {
        const { data, total } = await prescriptionRepo.findByPatientId(
            req.params.id,
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

module.exports = { list, getById, create, getPrescriptions };

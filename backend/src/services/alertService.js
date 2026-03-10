/**
 * ALERT SERVICE — Business logic for alert management.
 */
const alertRepo = require('../repositories/alertRepo');
const patientRepo = require('../repositories/patientRepo');
const { logAuditEvent } = require('./auditService');
const { NotFoundError } = require('../middleware/errorHandler');

async function listAlerts(filters) {
    return alertRepo.findAll(filters);
}

async function getAlert(id) {
    const alert = await alertRepo.findById(id);
    if (!alert) throw new NotFoundError('Alert not found');
    return alert;
}

async function acknowledgeAlert(id, user, overrideReason) {
    const alert = await alertRepo.acknowledge(id, user.id, overrideReason);
    if (!alert) throw new NotFoundError('Active alert not found');

    // Audit log (reliable write)
    await alertRepo.insertAuditLog(
        user.id,
        'ALERT_ACKNOWLEDGED',
        'interaction_alerts',
        id,
        { status: 'acknowledged', override_reason: overrideReason }
    );

    // Async Cassandra audit
    logAuditEvent({
        userId: user.id,
        userEmail: user.email,
        userRole: user.role,
        action: 'ALERT_ACKNOWLEDGED',
        resourceType: 'interaction_alerts',
        resourceId: id,
        details: JSON.stringify({ override_reason: overrideReason }),
        ipAddress: null,
        userAgent: null,
        requestMethod: 'POST',
        requestPath: `/api/v1/alerts/${id}/acknowledge`,
        responseStatus: 200,
        durationMs: 0,
    });

    return alert;
}

async function batchAcknowledgeAlerts(alertIds, user, overrideReason) {
    const acknowledged = await alertRepo.batchAcknowledge(alertIds, user.id, overrideReason);
    return acknowledged;
}

async function getPatientAlerts(patientId, pagination) {
    const prescriptionIds = await patientRepo.getPrescriptionIds(patientId);
    return alertRepo.findByPatientPrescriptions(prescriptionIds, pagination);
}

module.exports = {
    listAlerts,
    getAlert,
    acknowledgeAlert,
    batchAcknowledgeAlerts,
    getPatientAlerts,
};

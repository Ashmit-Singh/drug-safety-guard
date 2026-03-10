const cassandra = require('cassandra-driver');
const { v4: uuidv4 } = require('uuid');

let client = null;

const clientOptions = {
    contactPoints: (process.env.CASSANDRA_HOSTS || '127.0.0.1').split(','),
    localDataCenter: process.env.CASSANDRA_DATACENTER || 'dc1',
    keyspace: process.env.CASSANDRA_KEYSPACE || 'drug_interaction_analytics',
    protocolOptions: {
        port: parseInt(process.env.CASSANDRA_PORT) || 9042,
    },
    queryOptions: {
        consistency: cassandra.types.consistencies.localQuorum,
        prepare: true,
    },
    pooling: {
        coreConnectionsPerHost: {
            [cassandra.types.distance.local]: 2,
            [cassandra.types.distance.remote]: 1,
        },
    },
};

if (process.env.CASSANDRA_USERNAME && process.env.CASSANDRA_PASSWORD) {
    clientOptions.authProvider = new cassandra.auth.PlainTextAuthProvider(
        process.env.CASSANDRA_USERNAME,
        process.env.CASSANDRA_PASSWORD
    );
}

async function connectCassandra() {
    client = new cassandra.Client(clientOptions);
    await client.connect();
    return client;
}

async function shutdownCassandra() {
    if (client) {
        await client.shutdown();
        client = null;
    }
}

function getClient() {
    return client;
}

// ─── Write Helpers ─────────────────────────────────────

async function writeAuditEvent({
    userId, userEmail, userRole, action, resourceType, resourceId,
    details, ipAddress, userAgent, requestMethod, requestPath,
    responseStatus, durationMs,
}) {
    if (!client) return;

    const eventDate = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    const query = `
        INSERT INTO system_audit_events (
            event_date, created_at, event_id, user_id, user_email,
            user_role, action, resource_type, resource_id, details,
            ip_address, user_agent, request_method, request_path,
            response_status, duration_ms
        ) VALUES (?, toTimestamp(now()), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const params = [
        eventDate, cassandra.types.Uuid.fromString(uuidv4()),
        userId ? cassandra.types.Uuid.fromString(userId) : null,
        userEmail, userRole, action, resourceType,
        resourceId ? cassandra.types.Uuid.fromString(resourceId) : null,
        details, ipAddress, userAgent, requestMethod, requestPath,
        responseStatus, durationMs,
    ];

    await client.execute(query, params, { prepare: true, consistency: cassandra.types.consistencies.quorum });
}

async function writeAlertLog({
    hospitalId, alertId, prescriptionId, patientId, patientName,
    drugAName, drugBName, ingredientAName, ingredientBName,
    severity, clinicalEffect, recommendation, status, doctorName,
}) {
    if (!client) return;

    const query = `
        INSERT INTO interaction_alert_logs (
            hospital_id, created_at, alert_id, prescription_id,
            patient_id, patient_name, drug_a_name, drug_b_name,
            ingredient_a_name, ingredient_b_name, severity,
            clinical_effect, recommendation, status, doctor_name
        ) VALUES (?, toTimestamp(now()), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const params = [
        cassandra.types.Uuid.fromString(hospitalId),
        cassandra.types.Uuid.fromString(alertId),
        cassandra.types.Uuid.fromString(prescriptionId),
        cassandra.types.Uuid.fromString(patientId),
        patientName, drugAName, drugBName, ingredientAName,
        ingredientBName, severity, clinicalEffect, recommendation,
        status, doctorName,
    ];

    await client.execute(query, params, { prepare: true, consistency: cassandra.types.consistencies.quorum });
}

async function writePrescriptionHistory({
    patientId, prescriptionId, doctorId, doctorName, status,
    diagnosis, drugs, alertCount, maxSeverity, notes,
}) {
    if (!client) return;

    const query = `
        INSERT INTO prescription_history (
            patient_id, prescribed_at, prescription_id, doctor_id,
            doctor_name, status, diagnosis, drugs, alert_count,
            max_severity, notes
        ) VALUES (?, toTimestamp(now()), ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const drugTuples = (drugs || []).map(d =>
        cassandra.types.Tuple.fromArray([d.name, d.dosage, d.frequency])
    );

    const params = [
        cassandra.types.Uuid.fromString(patientId),
        cassandra.types.Uuid.fromString(prescriptionId),
        cassandra.types.Uuid.fromString(doctorId),
        doctorName, status, diagnosis, drugTuples,
        alertCount || 0, maxSeverity || 'none', notes,
    ];

    await client.execute(query, params, { prepare: true, consistency: cassandra.types.consistencies.quorum });
}

async function writeInteractionAnalytics({
    drugPairKey, prescriptionId, patientId, hospitalId,
    severity, ingredientAName, ingredientBName, drugAName,
    drugBName, doctorId,
}) {
    if (!client) return;

    const query = `
        INSERT INTO interaction_analytics (
            drug_pair_key, occurred_at, event_id, prescription_id,
            patient_id, hospital_id, severity, ingredient_a_name,
            ingredient_b_name, drug_a_name, drug_b_name, doctor_id
        ) VALUES (?, toTimestamp(now()), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const params = [
        drugPairKey,
        cassandra.types.Uuid.fromString(uuidv4()),
        cassandra.types.Uuid.fromString(prescriptionId),
        cassandra.types.Uuid.fromString(patientId),
        hospitalId ? cassandra.types.Uuid.fromString(hospitalId) : null,
        severity, ingredientAName, ingredientBName,
        drugAName, drugBName,
        doctorId ? cassandra.types.Uuid.fromString(doctorId) : null,
    ];

    await client.execute(query, params, { prepare: true, consistency: cassandra.types.consistencies.quorum });
}

async function updateDrugUsageCounters({ drugId, drugName, drugClass }) {
    if (!client) return;

    const month = new Date().toISOString().slice(0, 7); // YYYY-MM
    const query = `
        UPDATE drug_usage_analytics
        SET prescription_count = prescription_count + 1
        WHERE drug_id = ? AND month = ?
    `;
    await client.execute(query, [
        cassandra.types.Uuid.fromString(drugId), month
    ], { prepare: true });
}

async function writeUserActivity({ userId, action, resourceType, resourceId, details, ipAddress, sessionId }) {
    if (!client) return;

    const query = `
        INSERT INTO user_activity_logs (
            user_id, created_at, activity_id, action, resource_type,
            resource_id, details, ip_address, session_id
        ) VALUES (?, toTimestamp(now()), ?, ?, ?, ?, ?, ?, ?)
    `;
    const params = [
        cassandra.types.Uuid.fromString(userId),
        cassandra.types.Uuid.fromString(uuidv4()),
        action, resourceType,
        resourceId ? cassandra.types.Uuid.fromString(resourceId) : null,
        details, ipAddress, sessionId,
    ];

    await client.execute(query, params, { prepare: true });
}

module.exports = {
    connectCassandra,
    shutdownCassandra,
    getClient,
    writeAuditEvent,
    writeAlertLog,
    writePrescriptionHistory,
    writeInteractionAnalytics,
    updateDrugUsageCounters,
    writeUserActivity,
};

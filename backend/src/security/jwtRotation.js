/**
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * JWKS-BASED KEY ROTATION
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * Serves /.well-known/jwks.json with current + previous signing keys.
 * Tokens are signed with kid in header; verification tries all active keys.
 */
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const { getConfig } = require('../config/env');
const { logger } = require('../middleware/logger');

// In production, use a database table (jwt_keys) or secrets manager.
// This implementation uses in-memory keys for demonstration.
const keyStore = {
    keys: [],
    currentKeyIndex: 0,
};

function generateKeyPair() {
    const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
        modulusLength: 2048,
        publicKeyEncoding: { type: 'spki', format: 'pem' },
        privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
    });

    const kid = crypto.randomUUID();
    const createdAt = new Date();
    const expiresAt = new Date(Date.now() + 90 * 24 * 60 * 60 * 1000); // 90 days

    return { kid, publicKey, privateKey, createdAt, expiresAt, active: true };
}

function initializeKeys() {
    if (keyStore.keys.length === 0) {
        const key = generateKeyPair();
        keyStore.keys.push(key);
        keyStore.currentKeyIndex = 0;
        logger.info('JWT key pair initialized', { kid: key.kid });
    }
}

function getCurrentKey() {
    initializeKeys();
    return keyStore.keys[keyStore.currentKeyIndex];
}

function rotateKeys() {
    const newKey = generateKeyPair();
    keyStore.keys.push(newKey);
    keyStore.currentKeyIndex = keyStore.keys.length - 1;

    // Mark keys older than 180 days as inactive (but keep for verification window)
    const cutoff = new Date(Date.now() - 180 * 24 * 60 * 60 * 1000);
    for (const key of keyStore.keys) {
        if (key.createdAt < cutoff) key.active = false;
    }

    logger.info('JWT key rotated', {
        newKid: newKey.kid,
        totalKeys: keyStore.keys.length,
        activeKeys: keyStore.keys.filter(k => k.active).length,
    });

    return newKey;
}

function signToken(payload) {
    const key = getCurrentKey();
    return jwt.sign(payload, key.privateKey, {
        algorithm: 'RS256',
        keyid: key.kid,
        expiresIn: '1h',
    });
}

function verifyToken(token) {
    const decoded = jwt.decode(token, { complete: true });
    if (!decoded || !decoded.header.kid) {
        throw new Error('Token missing kid header');
    }

    const key = keyStore.keys.find(k => k.kid === decoded.header.kid && k.active);
    if (!key) {
        throw new Error('Signing key not found or expired');
    }

    return jwt.verify(token, key.publicKey, { algorithms: ['RS256'] });
}

/**
 * Express route handler for /.well-known/jwks.json
 */
function jwksEndpoint(req, res) {
    initializeKeys();
    const activeKeys = keyStore.keys.filter(k => k.active);

    const jwks = {
        keys: activeKeys.map(key => {
            const publicKeyDer = crypto.createPublicKey(key.publicKey)
                .export({ type: 'spki', format: 'der' });
            const n = publicKeyDer.toString('base64url');

            return {
                kty: 'RSA',
                use: 'sig',
                alg: 'RS256',
                kid: key.kid,
                n: n,
                e: 'AQAB',
            };
        }),
    };

    res.setHeader('Cache-Control', 'public, max-age=3600');
    res.json(jwks);
}

module.exports = {
    initializeKeys,
    getCurrentKey,
    rotateKeys,
    signToken,
    verifyToken,
    jwksEndpoint,
};

/**
 * DRUG CONTROLLER — HTTP handling for drugs and ingredients.
 */
const drugRepo = require('../repositories/drugRepo');
const { sendSuccess, sendPaginated } = require('../utils/response');
const { NotFoundError } = require('../middleware/errorHandler');

async function list(req, res, next) {
    try {
        const { data, total } = await drugRepo.findAll(req.validated);
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
        const data = await drugRepo.findById(req.params.id);
        if (!data) throw new NotFoundError('Drug not found');
        sendSuccess(res, data);
    } catch (err) {
        next(err);
    }
}

async function search(req, res, next) {
    try {
        const data = await drugRepo.search(req.validated.q);
        sendSuccess(res, data);
    } catch (err) {
        next(err);
    }
}

async function getIngredients(req, res, next) {
    try {
        const data = await drugRepo.getIngredients(req.params.id);
        sendSuccess(res, data);
    } catch (err) {
        next(err);
    }
}

// ─── Ingredient endpoints ──────────────────────────────
async function listIngredients(req, res, next) {
    try {
        const { data, total } = await drugRepo.findAllIngredients(req.validated);
        sendPaginated(res, data, {
            total,
            limit: req.validated.limit,
            offset: req.validated.offset,
        });
    } catch (err) {
        next(err);
    }
}

async function getIngredient(req, res, next) {
    try {
        const data = await drugRepo.findIngredientById(req.params.id);
        if (!data) throw new NotFoundError('Ingredient not found');
        sendSuccess(res, data);
    } catch (err) {
        next(err);
    }
}

async function searchIngredients(req, res, next) {
    try {
        const data = await drugRepo.searchIngredients(req.validated.q);
        sendSuccess(res, data);
    } catch (err) {
        next(err);
    }
}

async function getIngredientInteractions(req, res, next) {
    try {
        const data = await drugRepo.getIngredientInteractions(req.params.id);
        sendSuccess(res, data);
    } catch (err) {
        next(err);
    }
}

module.exports = {
    list, getById, search, getIngredients,
    listIngredients, getIngredient, searchIngredients, getIngredientInteractions,
};

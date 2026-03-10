/**
 * DRUG REPOSITORY — Data access for drugs, ingredients, drug_ingredients.
 */
const { supabase } = require('../middleware/auth');

async function findAll({ limit = 20, offset = 0 } = {}) {
    const { data, error, count } = await supabase
        .from('drugs')
        .select('id, brand_name, generic_name, drug_class, strength, manufacturer, created_at', { count: 'exact' })
        .is('deleted_at', null)
        .order('brand_name', { ascending: true })
        .range(offset, offset + limit - 1);

    if (error) throw error;
    return { data: data || [], total: count };
}

async function findById(id) {
    const { data, error } = await supabase
        .from('drugs')
        .select('*')
        .eq('id', id)
        .is('deleted_at', null)
        .single();

    if (error) return null;
    return data;
}

async function search(query) {
    const { data, error } = await supabase
        .from('drugs')
        .select('id, brand_name, generic_name, drug_class, strength')
        .is('deleted_at', null)
        .or(`brand_name.ilike.%${query}%,generic_name.ilike.%${query}%`)
        .limit(20);

    if (error) throw error;
    return data || [];
}

async function getIngredients(drugId) {
    const { data, error } = await supabase
        .from('drug_ingredients')
        .select(`
            ingredient_id,
            role,
            strength_per_unit,
            ingredients (id, name, cas_number, category, description)
        `)
        .eq('drug_id', drugId)
        .is('deleted_at', null);

    if (error) throw error;
    return data || [];
}

// ─── Ingredients ──────────────────────────────────────
async function findAllIngredients({ limit = 20, offset = 0 } = {}) {
    const { data, error, count } = await supabase
        .from('ingredients')
        .select('id, name, cas_number, category, description, created_at', { count: 'exact' })
        .is('deleted_at', null)
        .order('name', { ascending: true })
        .range(offset, offset + limit - 1);

    if (error) throw error;
    return { data: data || [], total: count };
}

async function findIngredientById(id) {
    const { data, error } = await supabase
        .from('ingredients')
        .select(`
            *,
            drug_ingredients (
                drug_id,
                drugs (id, brand_name, generic_name, drug_class)
            )
        `)
        .eq('id', id)
        .is('deleted_at', null)
        .single();

    if (error) return null;
    return data;
}

async function searchIngredients(query) {
    const { data, error } = await supabase
        .from('ingredients')
        .select('id, name, cas_number, category')
        .is('deleted_at', null)
        .ilike('name', `%${query}%`)
        .limit(20);

    if (error) throw error;
    return data || [];
}

async function getIngredientInteractions(ingredientId) {
    const { data, error } = await supabase
        .from('ingredient_interactions')
        .select('*')
        .is('deleted_at', null)
        .or(`ingredient_a_id.eq.${ingredientId},ingredient_b_id.eq.${ingredientId}`);

    if (error) throw error;
    return data || [];
}

module.exports = {
    findAll,
    findById,
    search,
    getIngredients,
    findAllIngredients,
    findIngredientById,
    searchIngredients,
    getIngredientInteractions,
};

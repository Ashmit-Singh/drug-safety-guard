import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../state/providers/app_providers.dart';
import '../../widgets/common/common_widgets.dart';

class DrugSearchScreen extends ConsumerStatefulWidget {
  const DrugSearchScreen({super.key});

  @override
  ConsumerState<DrugSearchScreen> createState() => _DrugSearchScreenState();
}

class _DrugSearchScreenState extends ConsumerState<DrugSearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drugsAsync = _searchQuery.length >= 2
        ? ref.watch(drugSearchProvider(_searchQuery))
        : ref.watch(drugsListProvider);

    return Scaffold(
      body: Column(
        children: [
          // ─── Search Bar ───────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search drugs by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // ─── Results ──────────────────────────────
          Expanded(
            child: drugsAsync.when(
              loading: () => const ShimmerList(itemCount: 6),
              error: (e, _) => ErrorState(message: e.toString(), onRetry: () {
                if (_searchQuery.length >= 2) {
                  ref.invalidate(drugSearchProvider(_searchQuery));
                } else {
                  ref.invalidate(drugsListProvider);
                }
              }),
              data: (result) {
                final drugs = result is List ? result : ((result as Map<String, dynamic>)['data'] as List? ?? []);
                if (drugs.isEmpty) {
                  return const EmptyState(icon: Icons.medication_outlined, message: 'No drugs found');
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: drugs.length,
                      itemBuilder: (context, index) {
                        final drug = drugs[index];
                        return _buildDrugCard(drug);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrugCard(Map<String, dynamic> drug) {
    return Card(
      child: InkWell(
        onTap: () => _showDrugDetail(drug),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medication, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drug['brand_name'] ?? 'Unknown',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          drug['generic_name'] ?? '',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (drug['drug_class'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        drug['drug_class'],
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.info, fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (drug['strength'] != null)
                    Text(
                      drug['strength'],
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDrugDetail(Map<String, dynamic> drug) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => _DrugDetailSheet(
          drug: drug,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _DrugDetailSheet extends ConsumerWidget {
  final Map<String, dynamic> drug;
  final ScrollController scrollController;

  const _DrugDetailSheet({required this.drug, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientsAsync = ref.watch(drugIngredientsProvider(drug['id']));

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(drug['brand_name'] ?? '', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700)),
                    Text(drug['generic_name'] ?? '', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _infoRow('Drug Class', drug['drug_class']),
          _infoRow('Manufacturer', drug['manufacturer']),
          _infoRow('Dosage Form', drug['dosage_form']),
          _infoRow('Strength', drug['strength']),
          _infoRow('Route', drug['route_of_administration']),
          _infoRow('NDC Code', drug['ndc_code']),
          const SizedBox(height: 20),
          Text('Ingredients', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ingredientsAsync.when(
            loading: () => const ShimmerList(itemCount: 3),
            error: (e, _) => Text('Error: ${e.toString()}'),
            data: (ingredients) {
              if (ingredients.isEmpty) {
                return Text('No ingredient data', style: GoogleFonts.inter(color: AppColors.textSecondary));
              }
              return Column(
                children: ingredients.map((ing) {
                  final ingredient = ing['ingredients'];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      ing['is_active_ingredient'] == true ? Icons.science : Icons.circle,
                      size: 18,
                      color: ing['is_active_ingredient'] == true ? AppColors.primary : AppColors.textLight,
                    ),
                    title: Text(ingredient?['name'] ?? 'Unknown', style: GoogleFonts.inter(fontSize: 14)),
                    subtitle: Text(
                      '${ingredient?['category'] ?? ''} ${ing['concentration'] != null ? '• ${ing['concentration']} ${ing['unit'] ?? ''}' : ''}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
                    ),
                    trailing: ing['is_active_ingredient'] == true
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Active', style: GoogleFonts.inter(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                          )
                        : null,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value.toString(), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

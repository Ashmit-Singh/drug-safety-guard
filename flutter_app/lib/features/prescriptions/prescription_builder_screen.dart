import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../state/providers/app_providers.dart';
import '../../widgets/common/common_widgets.dart';

class PrescriptionBuilderScreen extends ConsumerStatefulWidget {
  const PrescriptionBuilderScreen({super.key});

  @override
  ConsumerState<PrescriptionBuilderScreen> createState() => _PrescriptionBuilderScreenState();
}

class _PrescriptionBuilderScreenState extends ConsumerState<PrescriptionBuilderScreen> {
  final _drugSearchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _drugSearchController.dispose();
    super.dispose();
  }

  Future<void> _searchDrugs(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final api = ref.read(apiServiceProvider);
      final results = await api.searchDrugs(query);
      if (mounted) setState(() { _searchResults = results; _isSearching = false; });
    } catch (e) {
      if (mounted) setState(() { _isSearching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(prescriptionBuilderProvider);
    final builder = ref.read(prescriptionBuilderProvider.notifier);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.newPrescription),
        actions: [
          if (builderState.selectedDrugs.isNotEmpty)
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prescription saved successfully!')),
                );
                builder.reset();
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save'),
            ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => builder.reset(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _buildMainPanel(builderState, builder)),
                Container(width: 1, color: AppColors.divider),
                Expanded(flex: 4, child: _buildWarningPanel(builderState)),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildMainPanel(builderState, builder),
                  _buildWarningPanel(builderState),
                ],
              ),
            ),
    );
  }

  Widget _buildMainPanel(PrescriptionBuilderState state, PrescriptionBuilderNotifier builder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Patient Selector ───────────────────
          Text('Patient', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (state.patientName != null)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                title: Text(state.patientName!, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: const Text('Patient selected'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => builder.reset(),
                ),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_search, color: AppColors.textSecondary),
                title: Text(AppStrings.selectPatient, style: GoogleFonts.inter(color: AppColors.textSecondary)),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () => _showPatientSelector(builder),
              ),
            ),

          const SizedBox(height: 24),

          // ─── Drug Search ────────────────────────
          Text(AppStrings.searchDrugs, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _drugSearchController,
            decoration: InputDecoration(
              hintText: AppStrings.searchDrugsHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : _drugSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _drugSearchController.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null,
            ),
            onChanged: _searchDrugs,
          ),

          // ─── Search Results ─────────────────────
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final drug = _searchResults[index];
                  final isAlreadyAdded = state.selectedDrugs.any((d) => d['id'] == drug['id']);

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.medication, color: AppColors.primary, size: 20),
                    ),
                    title: Text(drug['brand_name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      '${drug['generic_name'] ?? ''} • ${drug['drug_class'] ?? ''} • ${drug['strength'] ?? ''}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: isAlreadyAdded
                        ? const Icon(Icons.check_circle, color: AppColors.success)
                        : const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    onTap: isAlreadyAdded
                        ? null
                        : () {
                            builder.addDrug(Map<String, dynamic>.from(drug));
                            _drugSearchController.clear();
                            setState(() => _searchResults = []);
                          },
                  );
                },
              ),
            ),

          const SizedBox(height: 24),

          // ─── Selected Drugs (Chips) ─────────────
          Text(AppStrings.selectedDrugs, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (state.selectedDrugs.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No drugs added yet. Search and add drugs above.',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.selectedDrugs.map((drug) {
                return Chip(
                  avatar: const Icon(Icons.medication, size: 16, color: AppColors.primary),
                  label: Text(drug['brand_name'] ?? drug['generic_name'] ?? 'Drug'),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => builder.removeDrug(drug['id']),
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                  side: BorderSide.none,
                  labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                );
              }).toList(),
            ),

          if (state.isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(state.error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.danger)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningPanel(PrescriptionBuilderState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.interactions.isEmpty ? Icons.check_circle : Icons.warning_amber_rounded,
                color: state.interactions.isEmpty ? AppColors.success : AppColors.danger,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.interactionWarnings,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              if (state.interactions.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${state.interactions.length}',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          if (state.interactions.isEmpty)
            Card(
              color: AppColors.success.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, color: AppColors.success, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.noInteractions,
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.success, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...state.interactions.map((interaction) {
              // Handle both regular alert format and engine check format
              final severity = interaction['severity']?.toString() ?? 'moderate';
              final drugAName = interaction['drugPair']?['drugAName'] ??
                  interaction['drug_a_name'] ?? 'Drug A';
              final drugBName = interaction['drugPair']?['drugBName'] ??
                  interaction['drug_b_name'] ?? 'Drug B';
              final ingAName = interaction['ingredientPair']?['ingredientAName'] ??
                  interaction['ingredient_a_name'] ?? 'Ingredient A';
              final ingBName = interaction['ingredientPair']?['ingredientBName'] ??
                  interaction['ingredient_b_name'] ?? 'Ingredient B';
              final clinicalEffect = interaction['clinicalEffect'] ??
                  interaction['clinical_effect'] ?? '';
              final recommendation = interaction['recommendation'] ?? '';

              return InteractionWarningCard(
                severity: severity,
                drugAName: drugAName.toString(),
                drugBName: drugBName.toString(),
                ingredientAName: ingAName.toString(),
                ingredientBName: ingBName.toString(),
                clinicalEffect: clinicalEffect.toString(),
                recommendation: recommendation.toString(),
              );
            }),
        ],
      ),
    );
  }

  void _showPatientSelector(PrescriptionBuilderNotifier builder) {
    // Demo: Using sample patient data
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Patient', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(child: Text('AT')),
              title: const Text('Alice Thompson'),
              subtitle: const Text('DOB: 1965-03-14 • Atrial fibrillation, T2D'),
              onTap: () {
                builder.setPatient('c0000001-0000-0000-0000-000000000001', 'Alice Thompson');
                builder.createPrescription('d0000001-0000-0000-0000-000000000001');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const CircleAvatar(child: Text('RC')),
              title: const Text('Robert Chen'),
              subtitle: const Text('DOB: 1978-09-22 • Hypertension, Hyperlipidemia'),
              onTap: () {
                builder.setPatient('c0000001-0000-0000-0000-000000000002', 'Robert Chen');
                builder.createPrescription('d0000001-0000-0000-0000-000000000001');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const CircleAvatar(child: Text('MG')),
              title: const Text('Maria Garcia'),
              subtitle: const Text('DOB: 1990-11-07 • T2D, Recurrent UTI'),
              onTap: () {
                builder.setPatient('c0000001-0000-0000-0000-000000000003', 'Maria Garcia');
                builder.createPrescription('d0000001-0000-0000-0000-000000000001');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

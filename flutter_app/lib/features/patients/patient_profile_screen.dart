import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../state/providers/app_providers.dart';
import '../../widgets/common/common_widgets.dart';

class PatientProfileScreen extends ConsumerWidget {
  final String patientId;
  const PatientProfileScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientProvider(patientId));
    final prescriptionsAsync = ref.watch(patientPrescriptionsProvider(patientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Profile')),
      body: patientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(patientProvider(patientId)),
        ),
        data: (patient) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(patientProvider(patientId));
            ref.invalidate(patientPrescriptionsProvider(patientId));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Patient Header Card ────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            '${(patient['first_name'] ?? 'U')[0]}${(patient['last_name'] ?? '')[0]}',
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${patient['first_name']} ${patient['last_name']}',
                                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'DOB: ${patient['date_of_birth'] ?? 'N/A'} • ${patient['gender'] ?? ''} • Blood: ${patient['blood_type'] ?? 'N/A'}',
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Allergies & Conditions ──────────
                if (patient['allergies'] != null && (patient['allergies'] as List).isNotEmpty) ...[
                  Text('Allergies', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (patient['allergies'] as List).map((a) => Chip(
                      avatar: const Icon(Icons.warning_amber, size: 14, color: AppColors.danger),
                      label: Text(a.toString()),
                      backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                      side: BorderSide.none,
                      labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.danger),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (patient['medical_conditions'] != null && (patient['medical_conditions'] as List).isNotEmpty) ...[
                  Text('Medical Conditions', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (patient['medical_conditions'] as List).map((c) => Chip(
                      label: Text(c.toString()),
                      backgroundColor: AppColors.info.withValues(alpha: 0.08),
                      side: BorderSide.none,
                      labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.info),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // ─── Prescription History (Timeline) ─
                Text('Prescription History', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                prescriptionsAsync.when(
                  loading: () => const ShimmerList(itemCount: 3),
                  error: (e, _) => ErrorState(message: e.toString()),
                  data: (result) {
                    final prescriptions = result['data'] as List? ?? [];
                    if (prescriptions.isEmpty) {
                      return const EmptyState(
                        icon: Icons.description_outlined,
                        message: 'No prescriptions found for this patient',
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: prescriptions.length,
                      itemBuilder: (context, index) {
                        final rx = prescriptions[index];
                        final drugs = (rx['prescription_drugs'] as List?) ?? [];
                        final doctor = rx['doctors'];
                        return _buildTimelineItem(rx, drugs, doctor, isLast: index == prescriptions.length - 1);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> rx, List drugs, dynamic doctor, {bool isLast = false}) {
    final statusColor = rx['status'] == 'approved'
        ? AppColors.success
        : rx['status'] == 'cancelled'
            ? AppColors.danger
            : AppColors.warning;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    border: Border.all(color: AppColors.surface, width: 2),
                    boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.3), blurRadius: 6)],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content card
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (rx['status'] ?? 'draft').toString().toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          (rx['prescribed_at'] ?? '').toString().split('T')[0],
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (doctor != null)
                      Text(
                        'Dr. ${doctor['first_name']} ${doctor['last_name']} — ${doctor['specialization'] ?? ''}',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    if (rx['diagnosis'] != null) ...[
                      const SizedBox(height: 4),
                      Text(rx['diagnosis'], style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                    if (drugs.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: drugs.map((d) {
                          final drugInfo = d['drugs'];
                          return Chip(
                            avatar: const Icon(Icons.medication, size: 14),
                            label: Text(drugInfo?['brand_name'] ?? 'Drug', style: GoogleFonts.inter(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

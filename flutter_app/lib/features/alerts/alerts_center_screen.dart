import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../state/providers/app_providers.dart';
import '../../widgets/common/common_widgets.dart';

class AlertsCenterScreen extends ConsumerStatefulWidget {
  const AlertsCenterScreen({super.key});

  @override
  ConsumerState<AlertsCenterScreen> createState() => _AlertsCenterScreenState();
}

class _AlertsCenterScreenState extends ConsumerState<AlertsCenterScreen> {
  String? _severityFilter;
  String? _statusFilter;
  final Set<String> _selectedAlertIds = {};
  bool _multiSelectMode = false;

  Map<String, dynamic> get _filterParams => {
        'limit': 50,
        'offset': 0,
        if (_severityFilter != null) 'severity': _severityFilter,
        if (_statusFilter != null) 'status': _statusFilter,
      };

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertsProvider(_filterParams));

    return Scaffold(
      body: Column(
        children: [
          // ─── Filter Bar ───────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text('Filters:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                _buildFilterChip('All', null, _severityFilter),
                _buildFilterChip('Severe', 'severe', _severityFilter),
                _buildFilterChip('Moderate', 'moderate', _severityFilter),
                _buildFilterChip('Mild', 'mild', _severityFilter),
                const Spacer(),
                if (_multiSelectMode && _selectedAlertIds.isNotEmpty)
                  FilledButton.icon(
                    onPressed: _batchAcknowledge,
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: Text('Acknowledge (${_selectedAlertIds.length})'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                IconButton(
                  icon: Icon(_multiSelectMode ? Icons.close : Icons.checklist),
                  onPressed: () {
                    setState(() {
                      _multiSelectMode = !_multiSelectMode;
                      if (!_multiSelectMode) _selectedAlertIds.clear();
                    });
                  },
                  tooltip: _multiSelectMode ? 'Cancel selection' : 'Multi-select',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ─── Alert List ───────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(alertsProvider(_filterParams)),
              child: alertsAsync.when(
                loading: () => const ShimmerList(itemCount: 5),
                error: (e, _) => ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(alertsProvider(_filterParams)),
                ),
                data: (result) {
                  final alerts = result['data'] as List? ?? [];
                  if (alerts.isEmpty) {
                    return const EmptyState(
                      icon: Icons.check_circle_outline,
                      message: AppStrings.noAlerts,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      final drugA = alert['drugs'] is Map ? alert['drugs'] : null;
                      final severity = alert['severity']?.toString() ?? 'moderate';
                      final alertId = alert['id']?.toString() ?? '';
                      final isSelected = _selectedAlertIds.contains(alertId);

                      // Extract patient name from nested prescription data
                      final prescription = alert['prescriptions'];
                      final patient = prescription is Map ? prescription['patients'] : null;
                      final patientName = patient is Map
                          ? '${patient['first_name']} ${patient['last_name']}'
                          : 'Patient';

                      final drugPair = '${drugA?['brand_name'] ?? 'Drug A'} ↔ Drug B';
                      final timestamp = (alert['created_at'] ?? '').toString().split('T')[0];

                      return GestureDetector(
                        onLongPress: () {
                          setState(() {
                            _multiSelectMode = true;
                            _selectedAlertIds.add(alertId);
                          });
                        },
                        child: AlertListCard(
                          severity: severity,
                          drugPair: drugPair,
                          patientName: patientName,
                          timestamp: timestamp,
                          status: alert['status']?.toString() ?? 'active',
                          isSelected: isSelected,
                          onTap: _multiSelectMode
                              ? () {
                                  setState(() {
                                    isSelected
                                        ? _selectedAlertIds.remove(alertId)
                                        : _selectedAlertIds.add(alertId);
                                  });
                                }
                              : null,
                          onAcknowledge: () => _acknowledgeAlert(alertId),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, String? current) {
    final isActive = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) {
          setState(() => _severityFilter = value);
          ref.invalidate(alertsProvider(_filterParams));
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
        ),
        side: BorderSide(
          color: isActive ? AppColors.primary : AppColors.divider,
        ),
      ),
    );
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.acknowledgeAlert(alertId);
      ref.invalidate(alertsProvider(_filterParams));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert acknowledged')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _batchAcknowledge() async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.batchAcknowledgeAlerts(_selectedAlertIds.toList());
      setState(() {
        _selectedAlertIds.clear();
        _multiSelectMode = false;
      });
      ref.invalidate(alertsProvider(_filterParams));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerts acknowledged')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }
}

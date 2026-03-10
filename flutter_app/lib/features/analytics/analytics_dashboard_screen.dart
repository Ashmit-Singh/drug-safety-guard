import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../state/providers/app_providers.dart';
import '../../widgets/common/common_widgets.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topAsync = ref.watch(topInteractionsProvider);
    final trendsAsync = ref.watch(alertTrendsProvider);
    final severityAsync = ref.watch(severityDistributionProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(topInteractionsProvider);
        ref.invalidate(alertTrendsProvider);
        ref.invalidate(severityDistributionProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analytics', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // ─── Row 1: Bar + Pie Charts ─────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildTopPairsSection(topAsync)),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _buildSeverityPieSection(severityAsync)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildTopPairsSection(topAsync),
                          const SizedBox(height: 16),
                          _buildSeverityPieSection(severityAsync),
                        ],
                      );
              },
            ),
            const SizedBox(height: 24),

            // ─── Alert Volume Over Time ──────────────
            Text('Alert Volume (30 Days)', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 280,
                  child: trendsAsync.when(
                    data: (trends) {
                      if (trends.isEmpty) return const EmptyState(icon: Icons.show_chart, message: 'No trend data');
                      return _buildTrendLine(trends);
                    },
                    loading: () => const ShimmerLoading(height: 280),
                    error: (e, _) => ErrorState(message: e.toString()),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Top Dangerous Pairs Table ───────────
            Text('Top 10 Dangerous Ingredient Pairs', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: topAsync.when(
                  data: (pairs) {
                    if (pairs.isEmpty) return const EmptyState(icon: Icons.table_chart, message: 'No interaction data');
                    return _buildPairsTable(pairs);
                  },
                  loading: () => const ShimmerList(itemCount: 5),
                  error: (e, _) => ErrorState(message: e.toString()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPairsSection(AsyncValue<List<dynamic>> topAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Most Common Interaction Pairs', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 250,
              child: topAsync.when(
                data: (pairs) {
                  if (pairs.isEmpty) return const EmptyState(icon: Icons.bar_chart, message: 'No data');
                  return _buildBarChart(pairs);
                },
                loading: () => const ShimmerLoading(height: 250),
                error: (e, _) => ErrorState(message: e.toString()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityPieSection(AsyncValue<List<dynamic>> severityAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Severity Distribution', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 250,
              child: severityAsync.when(
                data: (dist) {
                  if (dist.isEmpty) return const EmptyState(icon: Icons.pie_chart, message: 'No data');
                  return _buildPieChart(dist);
                },
                loading: () => const ShimmerLoading(height: 250),
                error: (e, _) => ErrorState(message: e.toString()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(List<dynamic> pairs) {
    final barGroups = <BarChartGroupData>[];
    final colors = [
      AppColors.danger, AppColors.warning, AppColors.primary,
      AppColors.info, AppColors.secondary, const Color(0xFF9C27B0),
      const Color(0xFF00BCD4), const Color(0xFFFF5722),
      const Color(0xFF795548), const Color(0xFF607D8B),
    ];

    for (var i = 0; i < pairs.length && i < 10; i++) {
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: (pairs[i]['count'] ?? pairs[i]['total_occurrences'] ?? 0).toDouble(),
            color: colors[i % colors.length],
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }

    return BarChart(BarChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: barGroups,
    ));
  }

  Widget _buildPieChart(List<dynamic> dist) {
    final colorMap = {
      'mild': const Color(0xFFF9A825),
      'moderate': AppColors.warning,
      'severe': AppColors.danger,
      'contraindicated': AppColors.warningContraindicated,
    };

    final sections = dist.map((d) {
      final severity = d['severity']?.toString() ?? 'mild';
      final count = (d['count'] ?? 0).toDouble();
      final pct = d['percentage'] ?? 0;
      return PieChartSectionData(
        value: count,
        color: colorMap[severity] ?? AppColors.textLight,
        title: '$pct%',
        titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
        radius: 50,
        badgeWidget: null,
      );
    }).toList();

    return Column(
      children: [
        Expanded(child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 40))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          children: dist.map((d) {
            final severity = d['severity']?.toString() ?? 'mild';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: colorMap[severity] ?? AppColors.textLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(severity, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTrendLine(List<dynamic> trends) {
    final spots = <FlSpot>[];
    for (var i = 0; i < trends.length; i++) {
      spots.add(FlSpot(i.toDouble(), (trends[i]['total'] ?? 0).toDouble()));
    }

    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: (trends.length / 6).ceilToDouble().clamp(1, 10),
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= trends.length) return const SizedBox();
              final date = trends[idx]['date']?.toString() ?? '';
              return Text(date.length >= 5 ? date.substring(5) : date,
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight));
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.08)),
        ),
      ],
    ));
  }

  Widget _buildPairsTable(List<dynamic> pairs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        dataTextStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Drug A')),
          DataColumn(label: Text('Drug B')),
          DataColumn(label: Text('Severity')),
          DataColumn(label: Text('Count'), numeric: true),
        ],
        rows: List.generate(pairs.length.clamp(0, 10), (i) {
          final pair = pairs[i];
          return DataRow(cells: [
            DataCell(Text('${i + 1}')),
            DataCell(Text(pair['drugAName']?.toString() ?? 'N/A')),
            DataCell(Text(pair['drugBName']?.toString() ?? 'N/A')),
            DataCell(SeverityBadge(severity: pair['severity']?.toString() ?? 'moderate')),
            DataCell(Text('${pair['count'] ?? pair['total_occurrences'] ?? 0}')),
          ]);
        }),
      ),
    );
  }
}

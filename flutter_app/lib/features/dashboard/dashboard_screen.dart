import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../state/providers/app_providers.dart';
import '../../widgets/common/common_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final trendsAsync = ref.watch(alertTrendsProvider);
    final topAsync = ref.watch(topInteractionsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(alertTrendsProvider);
        ref.invalidate(topInteractionsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // ─── Stat Cards ─────────────────────────
            statsAsync.when(
              data: (stats) => LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 600 ? 2 : 1;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.8,
                    children: [
                      StatCard(
                        title: AppStrings.totalPrescriptions,
                        value: '${stats['totalPrescriptions'] ?? 0}',
                        icon: Icons.description_outlined,
                        color: AppColors.primary,
                      ),
                      StatCard(
                        title: AppStrings.activePatients,
                        value: '${stats['activePatients'] ?? 0}',
                        icon: Icons.people_outline,
                        color: AppColors.info,
                      ),
                      StatCard(
                        title: AppStrings.alertsToday,
                        value: '${stats['alertsToday'] ?? 0}',
                        icon: Icons.notifications_active_outlined,
                        color: AppColors.warning,
                      ),
                      StatCard(
                        title: AppStrings.severeAlerts,
                        value: '${stats['severeAlerts'] ?? 0}',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.danger,
                      ),
                    ],
                  );
                },
              ),
              loading: () => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.8,
                children: List.generate(4, (_) => const ShimmerCard()),
              ),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(dashboardStatsProvider),
              ),
            ),

            const SizedBox(height: 28),

            // ─── Weekly Trends Chart ─────────────────
            Text(AppStrings.weeklyTrends, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 250,
                  child: trendsAsync.when(
                    data: (trends) => trends.isEmpty
                        ? const EmptyState(icon: Icons.show_chart, message: 'No trend data yet')
                        : _buildTrendChart(trends),
                    loading: () => const ShimmerLoading(height: 250),
                    error: (e, _) => ErrorState(message: e.toString()),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ─── Top Dangerous Pairs ─────────────────
            Text(AppStrings.dangerousPairs, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 250,
                  child: topAsync.when(
                    data: (pairs) => pairs.isEmpty
                        ? const EmptyState(icon: Icons.bar_chart, message: 'No interaction data yet')
                        : _buildTopPairsChart(pairs),
                    loading: () => const ShimmerLoading(height: 250),
                    error: (e, _) => ErrorState(message: e.toString()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(List<dynamic> trends) {
    final spots = <FlSpot>[];
    for (var i = 0; i < trends.length && i < 30; i++) {
      spots.add(FlSpot(i.toDouble(), (trends[i]['total'] ?? 0).toDouble()));
    }
    if (spots.isEmpty) spots.add(const FlSpot(0, 0));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.divider.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (trends.length / 6).ceilToDouble().clamp(1, 10),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= trends.length) return const SizedBox();
                final date = trends[idx]['date']?.toString() ?? '';
                return Text(
                  date.length >= 5 ? date.substring(5) : date,
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight),
                );
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
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) =>
              LineTooltipItem(
                '${spot.y.toInt()} alerts',
                GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTopPairsChart(List<dynamic> pairs) {
    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < pairs.length && i < 5; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (pairs[i]['count'] ?? pairs[i]['total_occurrences'] ?? 0).toDouble(),
              color: [AppColors.danger, AppColors.warning, AppColors.primary, AppColors.info, AppColors.secondary][i % 5],
              width: 28,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.divider.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= pairs.length) return const SizedBox();
                final label = '${pairs[idx]['drugAName'] ?? 'Drug'}\n↔\n${pairs[idx]['drugBName'] ?? 'Drug'}';
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 8, color: AppColors.textSecondary),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
              BarTooltipItem(
                '${rod.toY.toInt()} occurrences',
                GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
              ),
          ),
        ),
      ),
    );
  }
}

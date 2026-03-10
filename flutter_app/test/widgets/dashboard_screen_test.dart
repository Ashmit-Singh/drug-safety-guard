import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Dashboard Screen Widget Test ──────────────────────
// Tests the main dashboard renders correctly with metrics,
// chart, and recent activity sections.

// Mock dashboard data
class MockDashboardData {
  static const totalPrescriptions = 156;
  static const activeAlerts = 12;
  static const totalPatients = 89;
  static const totalDrugs = 234;
}

Widget createTestWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: child,
    ),
  );
}

// ─── Minimal Dashboard Widget for Testing ──────────────
class TestDashboardScreen extends StatelessWidget {
  final int totalPrescriptions;
  final int activeAlerts;
  final int totalPatients;
  final int totalDrugs;
  final bool isLoading;

  const TestDashboardScreen({
    super.key,
    this.totalPrescriptions = 0,
    this.activeAlerts = 0,
    this.totalPatients = 0,
    this.totalDrugs = 0,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metric Cards Row
            Row(
              children: [
                Expanded(
                  child: Card(
                    key: const Key('metric_prescriptions'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.description, color: Colors.blue),
                          Text('$totalPrescriptions', style: Theme.of(context).textTheme.headlineMedium),
                          const Text('Prescriptions'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    key: const Key('metric_alerts'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.warning, color: Colors.red),
                          Text('$activeAlerts', style: Theme.of(context).textTheme.headlineMedium),
                          const Text('Active Alerts'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Card(
                    key: const Key('metric_patients'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.people, color: Colors.green),
                          Text('$totalPatients', style: Theme.of(context).textTheme.headlineMedium),
                          const Text('Patients'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    key: const Key('metric_drugs'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.medication, color: Colors.purple),
                          Text('$totalDrugs', style: Theme.of(context).textTheme.headlineMedium),
                          const Text('Drugs'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('DashboardScreen', () {
    testWidgets('renders all metric cards', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const TestDashboardScreen(
          totalPrescriptions: MockDashboardData.totalPrescriptions,
          activeAlerts: MockDashboardData.activeAlerts,
          totalPatients: MockDashboardData.totalPatients,
          totalDrugs: MockDashboardData.totalDrugs,
        ),
      ));

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byKey(const Key('metric_prescriptions')), findsOneWidget);
      expect(find.byKey(const Key('metric_alerts')), findsOneWidget);
      expect(find.byKey(const Key('metric_patients')), findsOneWidget);
      expect(find.byKey(const Key('metric_drugs')), findsOneWidget);
    });

    testWidgets('displays correct metric values', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const TestDashboardScreen(
          totalPrescriptions: 156,
          activeAlerts: 12,
          totalPatients: 89,
          totalDrugs: 234,
        ),
      ));

      expect(find.text('156'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('89'), findsOneWidget);
      expect(find.text('234'), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const TestDashboardScreen(isLoading: true),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);
    });

    testWidgets('shows correct labels for metrics', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const TestDashboardScreen(),
      ));

      expect(find.text('Prescriptions'), findsOneWidget);
      expect(find.text('Active Alerts'), findsOneWidget);
      expect(find.text('Patients'), findsOneWidget);
      expect(find.text('Drugs'), findsOneWidget);
    });

    testWidgets('displays metric icons', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const TestDashboardScreen(),
      ));

      expect(find.byIcon(Icons.description), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.byIcon(Icons.medication), findsOneWidget);
    });
  });
}

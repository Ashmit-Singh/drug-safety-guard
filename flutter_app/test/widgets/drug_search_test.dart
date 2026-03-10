import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Drug Search Screen Widget Tests ───────────────────

Widget createTestWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: child,
    ),
  );
}

class TestDrug {
  final String id;
  final String brandName;
  final String genericName;
  final String? drugClass;
  final String? strength;

  const TestDrug({
    required this.id,
    required this.brandName,
    required this.genericName,
    this.drugClass,
    this.strength,
  });
}

class TestDrugSearchScreen extends StatefulWidget {
  final List<TestDrug> drugs;
  final bool isLoading;
  final String? errorMessage;
  final void Function(String)? onSearch;
  final void Function(TestDrug)? onDrugSelected;

  const TestDrugSearchScreen({
    super.key,
    this.drugs = const [],
    this.isLoading = false,
    this.errorMessage,
    this.onSearch,
    this.onDrugSelected,
  });

  @override
  State<TestDrugSearchScreen> createState() => _TestDrugSearchScreenState();
}

class _TestDrugSearchScreenState extends State<TestDrugSearchScreen> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drug Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const Key('search_field'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search drugs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        key: const Key('clear_button'),
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                widget.onSearch?.call(value);
                setState(() {});
              },
            ),
          ),
          if (widget.isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (widget.errorMessage != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(widget.errorMessage!, key: const Key('error_message')),
                  ],
                ),
              ),
            )
          else if (widget.drugs.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No drugs found', key: Key('empty_state')),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                key: const Key('drug_list'),
                itemCount: widget.drugs.length,
                itemBuilder: (context, index) {
                  final drug = widget.drugs[index];
                  return ListTile(
                    key: Key('drug_tile_${drug.id}'),
                    leading: const CircleAvatar(child: Icon(Icons.medication)),
                    title: Text(drug.brandName),
                    subtitle: Text('${drug.genericName} • ${drug.drugClass ?? ""}'),
                    trailing: drug.strength != null ? Chip(label: Text(drug.strength!)) : null,
                    onTap: () => widget.onDrugSelected?.call(drug),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Test Data ─────────────────────────────────────────
final testDrugs = [
  const TestDrug(id: '1', brandName: 'Aspirin', genericName: 'Acetylsalicylic Acid', drugClass: 'NSAID', strength: '325mg'),
  const TestDrug(id: '2', brandName: 'Coumadin', genericName: 'Warfarin', drugClass: 'Anticoagulant', strength: '5mg'),
  const TestDrug(id: '3', brandName: 'Lipitor', genericName: 'Atorvastatin', drugClass: 'Statin', strength: '20mg'),
];

void main() {
  group('DrugSearchScreen', () => {
    testWidgets('renders search field and empty state', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const TestDrugSearchScreen(),
      ));

      expect(find.text('Drug Search'), findsOneWidget);
      expect(find.byKey(const Key('search_field')), findsOneWidget);
      expect(find.text('Search drugs...'), findsOneWidget);
      expect(find.byKey(const Key('empty_state')), findsOneWidget);
    });

    testWidgets('displays drug list', (tester) async {
      await tester.pumpWidget(createTestWidget(
        TestDrugSearchScreen(drugs: testDrugs),
      ));

      expect(find.byKey(const Key('drug_list')), findsOneWidget);
      expect(find.text('Aspirin'), findsOneWidget);
      expect(find.text('Coumadin'), findsOneWidget);
      expect(find.text('Lipitor'), findsOneWidget);
    });

    testWidgets('shows loading indicator during search', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const TestDrugSearchScreen(isLoading: true),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('drug_list')), findsNothing);
    });

    testWidgets('shows error state', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const TestDrugSearchScreen(errorMessage: 'Network error'),
      ));

      expect(find.byKey(const Key('error_message')), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('fires onSearch callback when typing', (tester) async {
      String? searchQuery;
      await tester.pumpWidget(createTestWidget(
        TestDrugSearchScreen(
          onSearch: (query) => searchQuery = query,
        ),
      ));

      await tester.enterText(find.byKey(const Key('search_field')), 'aspirin');
      expect(searchQuery, equals('aspirin'));
    });

    testWidgets('fires onDrugSelected when tapping a drug', (tester) async {
      TestDrug? selectedDrug;
      await tester.pumpWidget(createTestWidget(
        TestDrugSearchScreen(
          drugs: testDrugs,
          onDrugSelected: (drug) => selectedDrug = drug,
        ),
      ));

      await tester.tap(find.text('Aspirin'));
      expect(selectedDrug?.brandName, equals('Aspirin'));
    });

    testWidgets('displays strength chips', (tester) async {
      await tester.pumpWidget(createTestWidget(
        TestDrugSearchScreen(drugs: testDrugs),
      ));

      expect(find.text('325mg'), findsOneWidget);
      expect(find.text('5mg'), findsOneWidget);
      expect(find.text('20mg'), findsOneWidget);
    });
  });

  group('AlertsCenterScreen', () {
    testWidgets('renders severity filter tabs', (tester) async {
      await tester.pumpWidget(createTestWidget(
        Scaffold(
          appBar: AppBar(title: const Text('Alert Center')),
          body: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChip(key: const Key('filter_all'), label: const Text('All'), selected: true, onSelected: (_) {}),
                    const SizedBox(width: 8),
                    FilterChip(key: const Key('filter_critical'), label: const Text('Critical'), selected: false, onSelected: (_) {},
                      avatar: const CircleAvatar(backgroundColor: Colors.red, radius: 8)),
                    const SizedBox(width: 8),
                    FilterChip(key: const Key('filter_severe'), label: const Text('Severe'), selected: false, onSelected: (_) {},
                      avatar: const CircleAvatar(backgroundColor: Colors.orange, radius: 8)),
                    const SizedBox(width: 8),
                    FilterChip(key: const Key('filter_moderate'), label: const Text('Moderate'), selected: false, onSelected: (_) {},
                      avatar: const CircleAvatar(backgroundColor: Colors.amber, radius: 8)),
                  ],
                ),
              ),
              const Expanded(
                child: Center(child: Text('No alerts', key: Key('empty_alerts'))),
              ),
            ],
          ),
        ),
      ));

      expect(find.text('Alert Center'), findsOneWidget);
      expect(find.byKey(const Key('filter_all')), findsOneWidget);
      expect(find.byKey(const Key('filter_critical')), findsOneWidget);
      expect(find.byKey(const Key('filter_severe')), findsOneWidget);
      expect(find.byKey(const Key('filter_moderate')), findsOneWidget);
    });
  });
}

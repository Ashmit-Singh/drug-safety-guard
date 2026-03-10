import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'services/api_service.dart';
import 'services/supabase_service.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/prescriptions/prescription_builder_screen.dart';
import 'features/drugs/drug_search_screen.dart';
import 'features/alerts/alerts_center_screen.dart';
import 'features/analytics/analytics_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize(
    url: const String.fromEnvironment('SUPABASE_URL',
        defaultValue: 'https://kikhxrzqarjdxvpjgbbs.supabase.co'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY',
        defaultValue: 'sb_publishable_1zZ9fhCmht-PQnUXKIhbog_sJehMQnx'),
  );

  // Initialize API service
  ApiService().initialize(
    baseUrl: const String.fromEnvironment('API_BASE_URL',
        defaultValue: 'http://localhost:3000/api/v1'),
  );

  runApp(const ProviderScope(child: DrugInteractionApp()));
}

class DrugInteractionApp extends ConsumerWidget {
  const DrugInteractionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StreamBuilder(
        stream: SupabaseService().authStateChanges,
        builder: (context, snapshot) {
          final isAuthenticated = SupabaseService().isAuthenticated;
          if (isAuthenticated) {
            return const AppShell();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// APP SHELL — NavigationRail (Desktop) / Drawer (Mobile)
// ═══════════════════════════════════════════════════════
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.description_outlined),
      selectedIcon: Icon(Icons.description),
      label: Text('Prescriptions'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.medication_outlined),
      selectedIcon: Icon(Icons.medication),
      label: Text('Drugs'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.notifications_outlined),
      selectedIcon: Icon(Icons.notifications),
      label: Text('Alerts'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: Text('Analytics'),
    ),
  ];

  Widget _buildBody() {
    return IndexedStack(
      index: _selectedIndex,
      children: const [
        DashboardScreen(),
        PrescriptionBuilderScreen(),
        DrugSearchScreen(),
        AlertsCenterScreen(),
        AnalyticsDashboardScreen(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(AppStrings.appName,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => setState(() => _selectedIndex = 3),
                ),
                _buildUserMenu(),
              ],
            ),
      drawer: isDesktop ? null : _buildDrawer(),
      body: isDesktop
          ? Row(
              children: [
                // ─── Navigation Rail ────────────────
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text('Drug Safety',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  trailing: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildUserMenu(),
                  ),
                  destinations: _destinations,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // ─── Main Content ───────────────────
                Expanded(child: _buildBody()),
              ],
            )
          : _buildBody(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
                const SizedBox(height: 12),
                Text(AppStrings.appName,
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('Clinical Decision Support',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _selectedIndex == 0,
            onTap: () { setState(() => _selectedIndex = 0); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Prescriptions'),
            selected: _selectedIndex == 1,
            onTap: () { setState(() => _selectedIndex = 1); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.medication),
            title: const Text('Drugs'),
            selected: _selectedIndex == 2,
            onTap: () { setState(() => _selectedIndex = 2); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Alerts'),
            selected: _selectedIndex == 3,
            onTap: () { setState(() => _selectedIndex = 3); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            selected: _selectedIndex == 4,
            onTap: () { setState(() => _selectedIndex = 4); Navigator.pop(context); },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('Sign Out'),
            onTap: () async {
              await SupabaseService().signOut();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildUserMenu() {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: const Icon(Icons.person, size: 18, color: AppColors.primary),
      ),
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        PopupMenuItem(
          child: Row(
            children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 8),
              Text('Profile', style: GoogleFonts.inter(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              const Icon(Icons.settings_outlined, size: 18),
              const SizedBox(width: 8),
              Text('Settings', style: GoogleFonts.inter(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () async => await SupabaseService().signOut(),
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18, color: AppColors.danger),
              const SizedBox(width: 8),
              Text('Sign Out', style: GoogleFonts.inter(fontSize: 13, color: AppColors.danger)),
            ],
          ),
        ),
      ],
    );
  }
}

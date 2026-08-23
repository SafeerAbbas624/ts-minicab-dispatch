import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../application/admin_providers.dart';
import 'action_log_screen.dart';
import 'admin_settings_screen.dart';
import 'create_admin_screen.dart';
import 'dashboard_screen.dart';
import 'drivers_shell_screen.dart';
import 'jobs_shell_screen.dart';
import 'payments_shell_screen.dart';
import 'tfl_export_screen.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  static const _titles = [
    'Dashboard',
    'Jobs',
    'Drivers',
    'Payments',
    'TfL Export',
    'Action Logs',
    'Settings',
  ];

  static const _screens = [
    DashboardScreen(),
    JobsShellScreen(),
    DriversShellScreen(),
    PaymentsShellScreen(),
    TflExportScreen(),
    ActionLogScreen(),
    AdminSettingsScreen(),
  ];

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.work_outline,
    Icons.people_outline,
    Icons.payments_outlined,
    Icons.directions_car_outlined,
    Icons.receipt_long_outlined,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperAdmin = ref.watch(authControllerProvider).role?.isSuperAdmin ?? false;
    final index = ref.watch(adminTabIndexProvider);

    void select(int i) {
      ref.read(adminTabIndexProvider.notifier).state = i;
      Navigator.of(context).pop();
    }

    return Scaffold(
      appBar: AppBar(title: Text(_titles[index])),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF0B5FFF)),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'TS Minicab Admin',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
              for (var i = 0; i < _titles.length; i++)
                ListTile(
                  leading: Icon(_icons[i]),
                  title: Text(_titles[i]),
                  selected: i == index,
                  onTap: () => select(i),
                ),
              if (isSuperAdmin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Create Admin'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreateAdminScreen()),
                    );
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(authControllerProvider.notifier).logout();
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: index, children: _screens),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import 'action_log_screen.dart';
import 'analytics_screen.dart';
import 'completed_jobs_screen.dart';
import 'create_admin_screen.dart';
import 'driver_queue_screen.dart';
import 'job_posting_screen.dart';
import 'pending_jobs_screen.dart';
import 'admin_settings_screen.dart';
import 'tfl_export_screen.dart';
import 'website_jobs_queue_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  static const _titles = [
    'Drivers',
    'Post a Job',
    'Website Jobs',
    'Active Jobs',
    'Payments',
    'TfL Export',
    'Analytics',
    'Action Log',
    'Settings',
  ];

  static const _screens = [
    DriverQueueScreen(),
    JobPostingScreen(),
    WebsiteJobsQueueScreen(),
    PendingJobsScreen(),
    CompletedJobsScreen(),
    TflExportScreen(),
    AnalyticsScreen(),
    ActionLogScreen(),
    AdminSettingsScreen(),
  ];

  void _select(int index) {
    setState(() => _index = index);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = ref.watch(authControllerProvider).role?.isSuperAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
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
                  title: Text(_titles[i]),
                  selected: i == _index,
                  onTap: () => _select(i),
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
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: _screens),
    );
  }
}

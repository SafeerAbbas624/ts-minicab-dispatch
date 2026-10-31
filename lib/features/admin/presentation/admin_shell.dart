import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/connectivity.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/responsive_nav_scaffold.dart';
import '../../auth/application/auth_controller.dart';
import '../application/admin_providers.dart';
import 'action_log_screen.dart';
import 'admin_settings_screen.dart';
import 'admins_screen.dart';
import 'audit_log_screen.dart';
import 'dashboard_screen.dart';
import 'drivers_shell_screen.dart';
import 'jobs_shell_screen.dart';
import 'payments_shell_screen.dart';
import 'records/records_shell_screen.dart';
import 'tfl_export_screen.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  static const _titles = [
    'Dashboard',
    'Jobs',
    'Drivers',
    'Payments',
    'TfL Export',
    'TfL Records',
    'Action Logs',
    'Booking Audit Log',
    'Settings',
  ];

  static const _screens = [
    DashboardScreen(),
    JobsShellScreen(),
    DriversShellScreen(),
    PaymentsShellScreen(),
    TflExportScreen(),
    RecordsShellScreen(),
    ActionLogScreen(),
    AuditLogScreen(),
    AdminSettingsScreen(),
  ];

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.work_outline,
    Icons.people_outline,
    Icons.payments_outlined,
    Icons.directions_car_outlined,
    Icons.folder_shared_outlined,
    Icons.receipt_long_outlined,
    Icons.timer_outlined,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperAdmin = ref.watch(authControllerProvider).role?.isSuperAdmin ?? false;
    final index = ref.watch(adminTabIndexProvider);
    // On desktop/web widths the drawer becomes a permanent sidebar instead
    // of a hamburger-triggered overlay, so it stops looking like a phone app
    // stretched into a browser — matches ResponsiveNavScaffold's breakpoint
    // used by the sub-tab shells nested inside each of these screens.
    final isDesktop = MediaQuery.sizeOf(context).width >= ResponsiveNavScaffold.desktopBreakpoint;

    void select(int i) {
      ref.read(adminTabIndexProvider.notifier).state = i;
      if (!isDesktop) Navigator.of(context).pop();
    }

    void closeDrawerThenPush(Widget screen) {
      if (!isDesktop) Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }

    final sidebar = SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLogo(height: 56),
                  const SizedBox(height: 4),
                  Text(
                    'Admin panel',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14),
                  ),
                ],
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
              title: const Text('Admins'),
              onTap: () => closeDrawerThenPush(const AdminsScreen()),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              if (!isDesktop) Navigator.of(context).pop();
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
    );

    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isDesktop ? 1100 : double.infinity),
      child: IndexedStack(index: index, children: _screens),
    );
    final aligned = isDesktop ? Align(alignment: Alignment.topCenter, child: content) : content;
    final body = Column(children: [const OfflineBanner(), Expanded(child: aligned)]);

    return Scaffold(
      appBar: AppBar(title: Text(_titles[index])),
      drawer: isDesktop ? null : Drawer(child: sidebar),
      body: isDesktop
          ? Row(
              children: [
                SizedBox(width: 260, child: Material(elevation: 1, child: sidebar)),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
    );
  }
}

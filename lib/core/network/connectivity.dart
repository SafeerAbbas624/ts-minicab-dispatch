import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/formatters.dart';

/// True while the device has any network. Starts optimistic so the banner
/// doesn't flash on launch.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool online(List<ConnectivityResult> r) => r.any((c) => c != ConnectivityResult.none);
  yield online(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(online);
});

bool isOnline(WidgetRef ref) => ref.watch(isOnlineProvider).valueOrNull ?? true;

/// Pinned above a shell's content while offline. Nothing is ever shown as
/// done without the server's confirmation, so actions simply wait here; the
/// shell refreshes its data when the connection comes back.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, this.driverMode = false});

  /// Drivers: job steps are saved and sent later, and the operating centre
  /// is one tap away (it can be reached by phone without data).
  final bool driverMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isOnline(ref)) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.cloud_off, size: 20, color: colors.onErrorContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  driverMode
                      ? "You're offline. Arrived / on board / complete taps are saved and sent when you're back online."
                      : "You're offline — job actions are paused until the connection returns.",
                  style: TextStyle(color: colors.onErrorContainer, fontWeight: FontWeight.w600),
                ),
              ),
              if (driverMode)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: colors.onErrorContainer),
                  onPressed: () => launchUrl(Uri.parse(operatorPhoneHref)),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call office'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Without this, Flutter web defaults to hash-based URLs
  // (app.tsminicab.com/#/delete-account) — every direct link to a public
  // route (privacy policy, terms, delete-account) silently failed to route
  // correctly for a fresh visit with no existing hash, landing on /login
  // instead, since go_router's initialLocation ('/splash') is all a
  // path-only URL resolves to under hash routing. This is a no-op on
  // non-web platforms (the package ships a stub there), so it's safe to
  // call unconditionally.
  usePathUrlStrategy();
  // A real Firebase Web app is now registered (see firebase_options.dart's
  // `web` FirebaseOptions), so this no longer needs to skip web — it did
  // for a while when there was no web entry and this call threw before
  // runApp() ever ran, crashing the page blank.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: 'TS Minicab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

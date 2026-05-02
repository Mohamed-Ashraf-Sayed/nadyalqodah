import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/providers.dart';
import 'data/services/version_service.dart';
import 'features/auth/auth_controller.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: QodahApp()));
}

class QodahApp extends ConsumerStatefulWidget {
  const QodahApp({super.key});

  @override
  ConsumerState<QodahApp> createState() => _QodahAppState();
}

class _QodahAppState extends ConsumerState<QodahApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wire dio client -> auth failure handler
      ref.read(dioClientProvider).onAuthFailed = () {
        ref.read(authControllerProvider.notifier).clearOnAuthFailure();
      };
      // Load persisted onboarding flag into the StateProvider
      initOnboardingState(ref);
      ref.read(authControllerProvider.notifier).bootstrap();
      // Check version against backend (force-update gate)
      runVersionCheck(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = createRouter(ref);
    return MaterialApp.router(
      title: 'نادي قضاة بني سويف',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (ctx, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );
  }
}

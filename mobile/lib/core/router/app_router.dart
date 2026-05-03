import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user.dart';
import '../../features/admin/screens/admin_member_edit_screen.dart';
import '../../features/admin/screens/admin_screen.dart';
import '../../features/admin/screens/stats_screen.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/screens/awaiting_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/common/main_shell.dart';
import '../../features/directory/screens/directory_screen.dart';
import '../../features/directory/screens/member_detail_screen.dart';
import '../../features/contracts/screens/contract_create_screen.dart';
import '../../features/contracts/screens/contracts_screen.dart';
import '../../features/events/screens/event_create_screen.dart';
import '../../features/events/screens/events_screen.dart';
import '../../features/news/screens/news_create_screen.dart';
import '../../features/news/screens/news_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/delete_account_screen.dart';
import '../../features/profile/screens/legal_screen.dart';
import '../../features/profile/screens/profile_edit_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/suggestions/screens/suggestion_create_screen.dart';
import '../../features/suggestions/screens/suggestions_screen.dart';
import '../../features/update/screens/update_required_screen.dart';
import '../../data/services/version_service.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(WidgetRef ref) {
  final notifier = _AuthNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (ctx, state) {
      final loc = state.matchedLocation;
      // Allow preview routes always (debug only)
      if (loc.startsWith('/preview/')) return null;
      // Public legal pages
      if (loc.startsWith('/legal/')) return null;

      // Force-update gate: blocks everything except itself.
      // Must short-circuit here — falling through to the onboarding/auth
      // logic below would cause /update-required → /onboarding redirect loops.
      final versionResult = ref.read(versionCheckProvider);
      if (loc == '/update-required') {
        // Stay on the gate while forceUpdate is true (or version still unknown).
        if (versionResult?.forceUpdate != false) return null;
        return '/';
      }
      if (versionResult?.forceUpdate == true) {
        return '/update-required';
      }

      // Onboarding can be visited directly
      if (loc == '/onboarding') return null;

      final auth = ref.read(authControllerProvider);
      if (!auth.initialized) return '/splash';

      final loggedIn = auth.user != null;
      final approved = auth.user?.status == UserStatus.approved;
      final onboardingState = ref.read(onboardingSeenProvider);

      final isAuthRoute =
          loc == '/login' || loc == '/register' || loc == '/forgot-password';
      final isAwaiting = loc == '/awaiting';
      final isSplash = loc == '/splash';

      // While onboarding state is still loading, keep splash
      if (onboardingState == null && !isSplash) return '/splash';

      // Show onboarding only when not logged in and explicitly not yet seen
      if (!loggedIn &&
          onboardingState == false &&
          loc != '/onboarding' &&
          !isSplash) {
        return '/onboarding';
      }

      if (isSplash) return loggedIn ? (approved ? '/' : '/awaiting') : '/login';
      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && isAuthRoute) return approved ? '/' : '/awaiting';
      if (loggedIn && !approved && !isAwaiting) return '/awaiting';
      if (loggedIn && approved && isAwaiting) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/awaiting', builder: (_, __) => const AwaitingApprovalScreen()),
      GoRoute(
        path: '/update-required',
        builder: (_, __) => const UpdateRequiredScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (ctx, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const DirectoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/events', builder: (_, __) => const EventsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/news', builder: (_, __) => const NewsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/contracts', builder: (_, __) => const ContractsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),

      // Top-level pushes (rendered above the shell)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/member/:id',
        builder: (ctx, st) => MemberDetailScreen(memberId: st.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/news/new',
        builder: (_, __) => const NewsCreateScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/contracts/new',
        builder: (_, __) => const ContractCreateScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/events/new',
        builder: (_, __) => const EventCreateScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/suggestions',
        builder: (_, __) => const SuggestionsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/suggestions/new',
        builder: (_, __) => const SuggestionCreateScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/admin/stats',
        builder: (_, __) => const StatsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/profile/edit',
        builder: (_, __) => const ProfileEditScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/delete-account',
        builder: (_, __) => const DeleteAccountScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/legal/privacy',
        builder: (_, __) => const LegalScreen(type: 'privacy'),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/legal/terms',
        builder: (_, __) => const LegalScreen(type: 'terms'),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/admin',
        builder: (_, __) => const AdminScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/admin/members/:id/edit',
        builder: (ctx, st) =>
            AdminMemberEditScreen(memberId: st.pathParameters['id']!),
      ),

      // Preview routes (debug)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/preview/awaiting',
        builder: (_, __) => const AwaitingApprovalScreen(),
      ),
    ],
  );
}

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this.ref) {
    ref.listen<AuthState>(authControllerProvider, (_, __) => notifyListeners());
    ref.listen<bool?>(
      onboardingSeenProvider,
      (_, __) => notifyListeners(),
    );
    ref.listen<VersionCheckResult?>(
      versionCheckProvider,
      (_, __) => notifyListeners(),
    );
  }
  final WidgetRef ref;
}

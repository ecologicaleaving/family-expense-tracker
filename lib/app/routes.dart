import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/home_screen.dart';
import '../features/groups/presentation/screens/no_group_screen.dart';
import '../features/groups/presentation/screens/create_group_screen.dart';
import '../features/groups/presentation/screens/join_group_screen.dart';
import '../features/groups/presentation/screens/group_details_screen.dart';
import '../features/scanner/presentation/screens/camera_screen.dart';
import '../features/scanner/presentation/screens/review_scan_screen.dart';
import '../features/expenses/presentation/screens/manual_expense_screen.dart';
import '../features/expenses/presentation/screens/expense_list_screen.dart';
import '../features/expenses/presentation/screens/expense_detail_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/auth/presentation/screens/main_navigation_screen.dart';
import '../features/auth/presentation/screens/profile_screen.dart';

/// Route paths
class AppRoutes {
  AppRoutes._();

  // Auth routes
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // Main routes
  static const home = '/';
  static const noGroup = '/no-group';
  static const createGroup = '/create-group';
  static const joinGroup = '/join-group';
  static const groupDetails = '/group-details';

  // Expense routes
  static const expenses = '/expenses';
  static const addExpense = '/add-expense';
  static const scanReceipt = '/scan-receipt';
  static const reviewScan = '/review-scan';
  static const expenseDetail = '/expense/:id';

  // Dashboard
  static const dashboard = '/dashboard';

  // Profile
  static const profile = '/profile';

  // Main navigation (with bottom bar)
  static const main = '/main';
}

/// Provider for the router
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,

    // Redirect based on auth state
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword;

      // Not authenticated and not on auth route -> go to login
      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      // Authenticated and on auth route -> go to home
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }

      // No redirect needed
      return null;
    },

    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app routes
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Group routes
      GoRoute(
        path: AppRoutes.noGroup,
        name: 'noGroup',
        builder: (context, state) => const NoGroupScreen(),
      ),
      GoRoute(
        path: AppRoutes.createGroup,
        name: 'createGroup',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: AppRoutes.joinGroup,
        name: 'joinGroup',
        builder: (context, state) => const JoinGroupScreen(),
      ),
      GoRoute(
        path: AppRoutes.groupDetails,
        name: 'groupDetails',
        builder: (context, state) => const GroupDetailsScreen(),
      ),

      // Expense routes
      GoRoute(
        path: AppRoutes.expenses,
        name: 'expenses',
        builder: (context, state) => const ExpenseListScreen(),
      ),
      GoRoute(
        path: AppRoutes.addExpense,
        name: 'addExpense',
        builder: (context, state) => const ManualExpenseScreen(),
      ),
      GoRoute(
        path: '/expense/:id',
        name: 'expenseDetail',
        builder: (context, state) {
          final expenseId = state.pathParameters['id']!;
          return ExpenseDetailScreen(expenseId: expenseId);
        },
      ),

      // Scanner routes
      GoRoute(
        path: AppRoutes.scanReceipt,
        name: 'scanReceipt',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: AppRoutes.reviewScan,
        name: 'reviewScan',
        builder: (context, state) => const ReviewScanScreen(),
      ),

      // Dashboard route (standalone, without bottom nav)
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // Profile route
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Main navigation with bottom bar
      GoRoute(
        path: AppRoutes.main,
        name: 'main',
        builder: (context, state) => const MainNavigationScreen(),
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Errore')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Pagina non trovata',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.matchedLocation),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Torna alla home'),
            ),
          ],
        ),
      ),
    ),
  );
});

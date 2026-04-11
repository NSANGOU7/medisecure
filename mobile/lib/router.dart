import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/appointments/appointments_screen.dart';
import 'screens/appointments/booking_screen.dart';
import 'screens/appointments/appointment_detail_screen.dart';
import 'screens/records/records_screen.dart';
import 'screens/records/prescription_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/logs_screen.dart';
import 'screens/shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/forgot');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      // ── Auth routes ──────────────────────────────────────────────────────
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot',   builder: (_, __) => const ForgotPasswordScreen()),

      // ── Shell (tab bar) ──────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, __) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/appointments',
            pageBuilder: (_, __) => const NoTransitionPage(child: AppointmentsScreen()),
            routes: [
              GoRoute(path: 'book',   builder: (_, __) => const BookingScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    AppointmentDetailScreen(id: int.parse(state.pathParameters['id']!)),
              ),
            ],
          ),
          GoRoute(
            path: '/records',
            pageBuilder: (_, __) => const NoTransitionPage(child: RecordsScreen()),
            routes: [
              GoRoute(path: 'prescriptions', builder: (_, __) => const PrescriptionScreen()),
            ],
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (_, __) => const NoTransitionPage(child: NotificationsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, __) => const NoTransitionPage(child: ProfileScreen()),
            routes: [
              GoRoute(path: 'edit', builder: (_, __) => const EditProfileScreen()),
            ],
          ),
        ],
      ),

      // ── Admin routes (no tab shell) ──────────────────────────────────────
      GoRoute(path: '/admin',           builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/users',     builder: (_, __) => const UserManagementScreen()),
      GoRoute(path: '/admin/logs',      builder: (_, __) => const LogsScreen()),
    ],
  );
});

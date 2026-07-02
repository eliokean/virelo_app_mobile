import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'route_names.dart';
import '../../../features/auth/presentation/pages/splash_page.dart';
import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/auth/presentation/pages/pin_login_page.dart';
import '../../../features/encaissement/presentation/pages/merchant_dashboard_page.dart';
import '../../../features/encaissement/presentation/pages/receive_payment_page.dart';
import '../../../features/historique/presentation/pages/history_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        name: RouteNames.login,
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        name: 'pin_login', // Note: better to add to RouteNames, but using inline for simplicity
        path: '/pin-login',
        builder: (context, state) => const PinLoginPage(),
      ),
      GoRoute(
        name: RouteNames.dashboard,
        path: '/dashboard',
        builder: (context, state) => const MerchantDashboardPage(),
      ),
      GoRoute(
        name: RouteNames.receivePayment,
        path: '/receive-payment',
        builder: (context, state) => const ReceivePaymentPage(),
      ),
      GoRoute(
        name: RouteNames.history,
        path: '/history',
        builder: (context, state) => const HistoryPage(),
      ),
    ],
  );
}

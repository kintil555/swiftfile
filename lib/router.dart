import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/send_screen.dart';
import 'screens/receive_screen.dart';
import 'screens/transfers_screen.dart';
import 'screens/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
    GoRoute(path: '/send', builder: (c, s) => const SendScreen()),
    GoRoute(path: '/receive', builder: (c, s) => const ReceiveScreen()),
    GoRoute(path: '/transfers', builder: (c, s) => const TransfersScreen()),
    GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
  ],
);

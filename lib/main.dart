import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'services/app_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/portal_provider.dart';
import 'screens/live_shell_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/advance_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/consumables_screen.dart';
import 'screens/evaluation_screen.dart';
import 'screens/home_screen.dart';
import 'screens/leave_screen.dart';
import 'screens/login_screen.dart';
import 'screens/memo_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/payroll_screen.dart';
import 'screens/permits_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/support_screen.dart';
import 'screens/team_approvals_screen.dart';
import 'screens/team_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  await AppNotificationService.initialize();
  runApp(const EmployeePortalApp());
}

class EmployeePortalApp extends StatelessWidget {
  const EmployeePortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PortalProvider()),
      ],
      child: MaterialApp(
        title: 'بوابة الموظف',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
        initialRoute: '/',
        routes: {
          '/': (context) => kIsWeb ? const SplashScreen() : const LiveShellScreen(),
          '/shell': (context) => const LiveShellScreen(),
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/advance-request': (context) => const AdvanceScreen(),
          '/attendance': (context) => const AttendanceScreen(),
          '/leave': (context) => const LeaveScreen(),
          '/permits': (context) => const PermitsScreen(),
          '/memo': (context) => const MemoScreen(),
          '/payroll': (context) => const PayrollScreen(),
          '/evaluation': (context) => const EvaluationScreen(),
          '/team-approvals': (context) => const TeamApprovalsScreen(),
          '/team': (context) => const TeamScreen(),
          '/consumables': (context) => const ConsumablesScreen(),
          '/support': (context) => const SupportScreen(),
          '/notifications': (context) => const NotificationsScreen(),
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/waste_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/waste_report_screen.dart';
import 'screens/waste_list_screen.dart';
import 'screens/buyers_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/waste_report_form_screen.dart';
import 'screens/submitted_reports_screen.dart';
import 'screens/report_detail_screen.dart';
import 'screens/buyer_register_screen.dart';
import 'screens/buyer_dashboard_screen.dart';
import 'screens/waste_marketplace_screen.dart';
import 'screens/buyer_waste_marketplace_screen.dart';
import 'screens/buyer_profile_screen.dart';
import 'screens/buyer_orders_screen.dart';
import 'screens/notifications_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WasteProvider()),
      ],
      child: MaterialApp(
        title: 'EcoWaste',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF10b981),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF10b981),
            secondary: Color(0xFF14b8a6),
            surface: Color(0xFF1E293B),
            background: Color(0xFF0F172A),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Color(0xFF1E293B),
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10b981), width: 2),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10b981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 2,
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const UserDashboardScreen(),
          '/waste-report': (context) => const WasteReportScreen(),
          '/waste-list': (context) => const WasteListScreen(),
          '/buyers': (context) => const BuyersScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/create-report': (context) => const WasteReportFormScreen(),
          '/submitted-reports': (context) => const SubmittedReportsScreen(),
          '/buyer-register': (context) => const BuyerRegisterScreen(),
          '/buyer-dashboard': (context) => const BuyerDashboardScreen(),
          '/buyer-marketplace': (context) => const BuyerWasteMarketplaceScreen(),
          '/buyer-profile': (context) => const BuyerProfileScreen(),
          '/buyer-orders': (context) => const BuyerOrdersScreen(),
          '/notifications': (context) => const NotificationsScreen(),
        },
      ),
    );
  }
}

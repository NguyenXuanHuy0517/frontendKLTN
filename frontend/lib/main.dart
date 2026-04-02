import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/session/session_store.dart';
import 'core/theme/app_theme.dart';
import 'providers/admin_dashboard_provider.dart';
import 'providers/admin_host_provider.dart';
import 'providers/admin_revenue_provider.dart';
import 'providers/admin_room_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/area_provider.dart';
import 'providers/room_provider.dart';
import 'providers/tenant_provider.dart';
import 'providers/deposit_provider.dart';
import 'providers/contract_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/issue_provider.dart';
import 'providers/host_invoice_list_provider.dart';
import 'providers/host_issue_list_provider.dart';
import 'providers/host_notification_list_provider.dart';
import 'providers/host_room_list_provider.dart';
import 'providers/report_provider.dart';
import 'providers/tenant_dashboard_provider.dart';
import 'providers/tenant_invoice_list_provider.dart';
import 'providers/tenant_issue_list_provider.dart';
import 'providers/tenant_notification_list_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_badge_provider.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionStore.instance.init();
  final themeProvider = ThemeProvider();
  await themeProvider.init();
  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const MyApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
        ChangeNotifierProvider(create: (_) => AdminHostProvider()),
        ChangeNotifierProvider(create: (_) => AdminRoomProvider()),
        ChangeNotifierProvider(create: (_) => AdminRevenueProvider()),
        ChangeNotifierProvider(create: (_) => AreaProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => TenantProvider()),
        ChangeNotifierProvider(create: (_) => DepositProvider()),
        ChangeNotifierProvider(create: (_) => ContractProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => IssueProvider()),
        ChangeNotifierProvider(create: (_) => HostRoomListProvider()),
        ChangeNotifierProvider(create: (_) => HostInvoiceListProvider()),
        ChangeNotifierProvider(create: (_) => TenantInvoiceListProvider()),
        ChangeNotifierProvider(create: (_) => HostIssueListProvider()),
        ChangeNotifierProvider(create: (_) => TenantIssueListProvider()),
        ChangeNotifierProvider(create: (_) => HostNotificationListProvider()),
        ChangeNotifierProvider(create: (_) => TenantNotificationListProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => TenantDashboardProvider()),
        ChangeNotifierProvider(create: (_) => NotificationBadgeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp.router(
            title: 'SmartRoomMS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
            routerConfig: AppRouter.router,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('vi', 'VN'),
              Locale('en', 'US'),
            ],
          );
        },
      ),
    );
  }
}

import 'package:go_router/go_router.dart';
import 'data/services/auth_service.dart';

// Auth
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';

// Host
import 'presentation/host/dashboard/dashboard_screen.dart';
import 'presentation/host/area/area_list_screen.dart';
import 'presentation/host/area/area_form_screen.dart';
import 'presentation/host/room/room_list_screen.dart';
import 'presentation/host/room/room_detail_screen.dart';
import 'presentation/host/room/room_form_screen.dart';
import 'presentation/host/tenant/tenant_list_screen.dart';
import 'presentation/host/tenant/tenant_detail_screen.dart';
import 'presentation/host/tenant/tenant_form_screen.dart';
import 'presentation/host/deposit/deposit_list_screen.dart';
import 'presentation/host/contract/contract_list_screen.dart';
import 'presentation/host/contract/contract_detail_screen.dart';
import 'presentation/host/contract/contract_form_screen.dart';
import 'presentation/host/invoice/invoice_list_screen.dart';
import 'presentation/host/invoice/invoice_detail_screen.dart';
import 'presentation/host/issue/issue_list_screen.dart';
import 'presentation/host/issue/issue_detail_screen.dart';

// Tenant
import 'presentation/tenant/dashboard/tenant_dashboard_screen.dart';
import 'presentation/tenant/invoice/tenant_invoice_list_screen.dart';
import 'presentation/tenant/invoice/tenant_invoice_detail_screen.dart';
import 'presentation/tenant/issue/tenant_issue_list_screen.dart';
import 'presentation/tenant/issue/tenant_issue_detail_screen.dart';
import 'presentation/tenant/contract/tenant_contract_screen.dart';
import 'presentation/tenant/chatbot/tenant_chatbot_screen.dart';
import 'presentation/tenant/profile/tenant_profile_screen.dart';
import 'presentation/tenant/notification/tenant_notification_screen.dart';

class AppRouter {
  static final _authService = AuthService();

  static final router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = await _authService.isLoggedIn();
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';

      if (isLoggedIn && isAuthRoute) {
        final role = await _authService.getRole();
        if (role == 'TENANT') return '/tenant/dashboard';
        return '/host/dashboard';
      }
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // ──────────────────────────────────────────────────────
      // HOST ROUTES
      // ──────────────────────────────────────────────────────
      GoRoute(
        path: '/host/dashboard',
        builder: (_, __) => const DashboardScreen(),
      ),

      // Areas
      GoRoute(path: '/host/areas', builder: (_, __) => const AreaListScreen()),
      GoRoute(
        path: '/host/areas/new',
        builder: (_, __) => const AreaFormScreen(),
      ),
      GoRoute(
        path: '/host/areas/:areaId/edit',
        builder: (_, state) =>
            AreaFormScreen(areaId: int.parse(state.pathParameters['areaId']!)),
      ),

      // Rooms
      GoRoute(
        path: '/host/rooms',
        builder: (_, state) => RoomListScreen(
          areaId: int.tryParse(state.uri.queryParameters['areaId'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/host/rooms/new',
        builder: (_, state) => RoomFormScreen(
          initialAreaId: int.tryParse(
            state.uri.queryParameters['areaId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/host/rooms/:roomId',
        builder: (_, state) => RoomDetailScreen(
          roomId: int.parse(state.pathParameters['roomId']!),
        ),
      ),
      GoRoute(
        path: '/host/rooms/:roomId/edit',
        builder: (_, state) =>
            RoomFormScreen(roomId: int.parse(state.pathParameters['roomId']!)),
      ),

      // Tenants
      GoRoute(
        path: '/host/tenants',
        builder: (_, __) => const TenantListScreen(),
      ),
      GoRoute(
        path: '/host/tenants/new',
        builder: (_, __) => const TenantFormScreen(),
      ),
      GoRoute(
        path: '/host/tenants/:tenantId',
        builder: (_, state) => TenantDetailScreen(
          tenantId: int.parse(state.pathParameters['tenantId']!),
        ),
      ),

      // Deposits
      GoRoute(
        path: '/host/deposits',
        builder: (_, __) => const DepositListScreen(),
      ),

      // Contracts
      GoRoute(
        path: '/host/contracts',
        builder: (_, __) => const ContractListScreen(),
      ),
      GoRoute(
        path: '/host/contracts/new',
        builder: (_, __) => const ContractFormScreen(),
      ),
      GoRoute(
        path: '/host/contracts/:contractId',
        builder: (_, state) => ContractDetailScreen(
          contractId: int.parse(state.pathParameters['contractId']!),
        ),
      ),

      // Invoices
      GoRoute(
        path: '/host/invoices',
        builder: (_, __) => const InvoiceListScreen(),
      ),
      GoRoute(
        path: '/host/invoices/:invoiceId',
        builder: (_, state) => InvoiceDetailScreen(
          invoiceId: int.parse(state.pathParameters['invoiceId']!),
        ),
      ),

      // Issues
      GoRoute(
        path: '/host/issues',
        builder: (_, __) => const IssueListScreen(),
      ),
      GoRoute(
        path: '/host/issues/:issueId',
        builder: (_, state) => IssueDetailScreen(
          issueId: int.parse(state.pathParameters['issueId']!),
        ),
      ),

      // ──────────────────────────────────────────────────────
      // TENANT ROUTES
      // ──────────────────────────────────────────────────────
      GoRoute(
        path: '/tenant/dashboard',
        builder: (_, __) => const TenantDashboardScreen(),
      ),

      // Invoices
      GoRoute(
        path: '/tenant/invoices',
        builder: (_, __) => const TenantInvoiceListScreen(),
      ),
      GoRoute(
        path: '/tenant/invoices/:invoiceId',
        builder: (_, state) => TenantInvoiceDetailScreen(
          invoiceId: int.parse(state.pathParameters['invoiceId']!),
        ),
      ),

      // Issues
      GoRoute(
        path: '/tenant/issues',
        builder: (_, __) => const TenantIssueListScreen(),
      ),
      GoRoute(
        path: '/tenant/issues/:issueId',
        builder: (_, state) => TenantIssueDetailScreen(
          issueId: int.parse(state.pathParameters['issueId']!),
        ),
      ),

      // Contract
      GoRoute(
        path: '/tenant/contract',
        builder: (_, __) => const TenantContractScreen(),
      ),

      // Chatbot
      GoRoute(
        path: '/tenant/chatbot',
        builder: (_, __) => const TenantChatbotScreen(),
      ),

      // Profile
      GoRoute(
        path: '/tenant/profile',
        builder: (_, __) => const TenantProfileScreen(),
      ),

      // Notifications
      GoRoute(
        path: '/tenant/notifications',
        builder: (_, __) => const TenantNotificationScreen(),
      ),
    ],

    errorBuilder: (_, __) => const LoginScreen(),
  );
}

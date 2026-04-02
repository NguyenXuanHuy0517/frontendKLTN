// Cấu hình toàn bộ route cho ứng dụng Flutter theo từng vai trò.
import 'package:go_router/go_router.dart';

import 'data/services/auth_service.dart';
import 'presentation/admin/dashboard/admin_dashboard_screen.dart';
import 'presentation/admin/host/admin_host_detail_screen.dart';
import 'presentation/admin/host/admin_host_list_screen.dart';
import 'presentation/admin/revenue/admin_revenue_screen.dart';
import 'presentation/admin/room/admin_room_audit_screen.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/auth/reset_password_screen.dart';
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
import 'presentation/host/notification/host_notification_screen.dart';
import 'presentation/host/notification/host_notification_send_screen.dart';
import 'presentation/host/service/host_service_management_screen.dart';
import 'presentation/host/profile/host_profile_screen.dart';
import 'presentation/tenant/dashboard/tenant_dashboard_screen.dart';
import 'presentation/tenant/invoice/tenant_invoice_list_screen.dart';
import 'presentation/tenant/invoice/tenant_invoice_detail_screen.dart';
import 'presentation/tenant/issue/tenant_issue_list_screen.dart';
import 'presentation/tenant/issue/tenant_issue_detail_screen.dart';
import 'presentation/tenant/contract/tenant_contract_screen.dart';
import 'presentation/tenant/chatbot/tenant_chatbot_screen.dart';
import 'presentation/tenant/profile/tenant_profile_screen.dart';
import 'presentation/tenant/notification/tenant_notification_screen.dart';
import 'presentation/tenant/service/tenant_service_screen.dart';

class AppRouter {
  static final _authService = AuthService();

  static String _homeForRole(String? role) {
    switch ((role ?? '').toUpperCase()) {
      case 'ADMIN':
        return '/admin/dashboard';
      case 'TENANT':
        return '/tenant/dashboard';
      default:
        return '/host/dashboard';
    }
  }

  static final router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = await _authService.isLoggedIn();
      final location = state.matchedLocation;
      final role = (await _authService.getRole())?.toUpperCase();
      final isLoginOrRegister = location == '/login' || location == '/register';
      final isPublicAuthRoute =
          isLoginOrRegister || location == '/reset-password';

      if (!isLoggedIn && !isPublicAuthRoute) return '/login';

      if (isLoggedIn && isLoginOrRegister) {
        return _homeForRole(role);
      }

      if (isLoggedIn && location.startsWith('/admin') && role != 'ADMIN') {
        return _homeForRole(role);
      }

      if (isLoggedIn && location.startsWith('/host') && role != 'HOST') {
        return _homeForRole(role);
      }

      if (isLoggedIn && location.startsWith('/tenant') && role != 'TENANT') {
        return _homeForRole(role);
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) =>
            ResetPasswordScreen(token: state.uri.queryParameters['token']),
      ),

      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/hosts',
        builder: (context, state) => const AdminHostListScreen(),
      ),
      GoRoute(
        path: '/admin/hosts/:hostId',
        builder: (context, state) => AdminHostDetailScreen(
          hostId: int.parse(state.pathParameters['hostId']!),
        ),
      ),
      GoRoute(
        path: '/admin/rooms',
        builder: (context, state) => const AdminRoomAuditScreen(),
      ),
      GoRoute(
        path: '/admin/revenue',
        builder: (context, state) => const AdminRevenueScreen(),
      ),

      GoRoute(
        path: '/host/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/host/areas',
        builder: (context, state) => const AreaListScreen(),
      ),
      GoRoute(
        path: '/host/areas/new',
        builder: (context, state) => const AreaFormScreen(),
      ),
      GoRoute(
        path: '/host/areas/:areaId/edit',
        builder: (context, state) =>
            AreaFormScreen(areaId: int.parse(state.pathParameters['areaId']!)),
      ),
      GoRoute(
        path: '/host/services',
        builder: (context, state) => const HostServiceManagementScreen(),
      ),
      GoRoute(
        path: '/host/areas/:areaId/services',
        builder: (context, state) => HostServiceManagementScreen(
          areaId: int.parse(state.pathParameters['areaId']!),
          areaName: state.uri.queryParameters['areaName'],
        ),
      ),
      GoRoute(
        path: '/host/rooms',
        builder: (context, state) => RoomListScreen(
          areaId: int.tryParse(state.uri.queryParameters['areaId'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/host/rooms/new',
        builder: (context, state) => RoomFormScreen(
          initialAreaId: int.tryParse(
            state.uri.queryParameters['areaId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/host/rooms/:roomId',
        builder: (context, state) => RoomDetailScreen(
          roomId: int.parse(state.pathParameters['roomId']!),
        ),
      ),
      GoRoute(
        path: '/host/rooms/:roomId/edit',
        builder: (context, state) =>
            RoomFormScreen(roomId: int.parse(state.pathParameters['roomId']!)),
      ),
      GoRoute(
        path: '/host/tenants',
        builder: (context, state) => const TenantListScreen(),
      ),
      GoRoute(
        path: '/host/tenants/new',
        builder: (context, state) => const TenantFormScreen(),
      ),
      GoRoute(
        path: '/host/tenants/:tenantId',
        builder: (context, state) => TenantDetailScreen(
          tenantId: int.parse(state.pathParameters['tenantId']!),
        ),
      ),
      GoRoute(
        path: '/host/deposits',
        builder: (context, state) => const DepositListScreen(),
      ),
      GoRoute(
        path: '/host/contracts',
        builder: (context, state) => const ContractListScreen(),
      ),
      GoRoute(
        path: '/host/contracts/new',
        builder: (context, state) => const ContractFormScreen(),
      ),
      GoRoute(
        path: '/host/contracts/:contractId',
        builder: (context, state) => ContractDetailScreen(
          contractId: int.parse(state.pathParameters['contractId']!),
        ),
      ),
      GoRoute(
        path: '/host/invoices',
        builder: (context, state) => const InvoiceListScreen(),
      ),
      GoRoute(
        path: '/host/invoices/:invoiceId',
        builder: (context, state) => InvoiceDetailScreen(
          invoiceId: int.parse(state.pathParameters['invoiceId']!),
        ),
      ),
      GoRoute(
        path: '/host/issues',
        builder: (context, state) => const IssueListScreen(),
      ),
      GoRoute(
        path: '/host/issues/:issueId',
        builder: (context, state) => IssueDetailScreen(
          issueId: int.parse(state.pathParameters['issueId']!),
        ),
      ),
      GoRoute(
        path: '/host/notifications',
        builder: (context, state) => const HostNotificationScreen(),
      ),
      GoRoute(
        path: '/host/notifications/send',
        builder: (context, state) => const HostNotificationSendScreen(),
      ),
      GoRoute(
        path: '/host/profile',
        builder: (context, state) => const HostProfileScreen(),
      ),

      GoRoute(
        path: '/tenant/dashboard',
        builder: (context, state) => const TenantDashboardScreen(),
      ),
      GoRoute(
        path: '/tenant/invoices',
        builder: (context, state) => const TenantInvoiceListScreen(),
      ),
      GoRoute(
        path: '/tenant/invoices/:invoiceId',
        builder: (context, state) => TenantInvoiceDetailScreen(
          invoiceId: int.parse(state.pathParameters['invoiceId']!),
        ),
      ),
      GoRoute(
        path: '/tenant/issues',
        builder: (context, state) => const TenantIssueListScreen(),
      ),
      GoRoute(
        path: '/tenant/issues/:issueId',
        builder: (context, state) => TenantIssueDetailScreen(
          issueId: int.parse(state.pathParameters['issueId']!),
        ),
      ),
      GoRoute(
        path: '/tenant/contract',
        builder: (context, state) => const TenantContractScreen(),
      ),
      GoRoute(
        path: '/tenant/services',
        builder: (context, state) => const TenantServiceScreen(),
      ),
      GoRoute(
        path: '/tenant/chatbot',
        builder: (context, state) => const TenantChatbotScreen(),
      ),
      GoRoute(
        path: '/tenant/profile',
        builder: (context, state) => const TenantProfileScreen(),
      ),
      GoRoute(
        path: '/tenant/notifications',
        builder: (context, state) => const TenantNotificationScreen(),
      ),
    ],
    errorBuilder: (context, state) => const LoginScreen(),
  );
}

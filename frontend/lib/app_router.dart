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

class AppRouter {
  static final _authService = AuthService();

  static final router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = await _authService.isLoggedIn();
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/host/dashboard';
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Dashboard ─────────────────────────────────────
      GoRoute(
        path: '/host/dashboard',
        builder: (_, __) => const DashboardScreen(),
      ),

      // ── Areas ─────────────────────────────────────────
      GoRoute(
        path: '/host/areas',
        builder: (_, __) => const AreaListScreen(),
      ),
      GoRoute(
        path: '/host/areas/new',
        builder: (_, __) => const AreaFormScreen(),
      ),
      GoRoute(
        path: '/host/areas/:areaId/edit',
        builder: (_, state) => AreaFormScreen(
          areaId: int.parse(state.pathParameters['areaId']!),
        ),
      ),

      // ── Rooms ─────────────────────────────────────────
      GoRoute(
        path: '/host/rooms',
        builder: (_, __) => const RoomListScreen(),
      ),
      GoRoute(
        path: '/host/rooms/new',
        builder: (_, __) => const RoomFormScreen(),
      ),
      GoRoute(
        path: '/host/rooms/:roomId',
        builder: (_, state) => RoomDetailScreen(
          roomId: int.parse(state.pathParameters['roomId']!),
        ),
      ),
      GoRoute(
        path: '/host/rooms/:roomId/edit',
        builder: (_, state) => RoomFormScreen(
          roomId: int.parse(state.pathParameters['roomId']!),
        ),
      ),

      // ── Tenants ───────────────────────────────────────
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

      // ── Deposits ──────────────────────────────────────
      GoRoute(
        path: '/host/deposits',
        builder: (_, __) => const DepositListScreen(),
      ),

      // ── Contracts ─────────────────────────────────────
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

      // ── Invoices ──────────────────────────────────────
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

      // ── Issues ────────────────────────────────────────
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
    ],

    errorBuilder: (_, state) => const LoginScreen(),
  );
}
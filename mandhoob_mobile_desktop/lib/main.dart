import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'services/auth_service.dart';
import 'widgets/access_denied_widget.dart';
import 'widgets/adaptive_scaffold.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/sales/sales_list_screen.dart';
import 'screens/purchase/purchase_list_screen.dart';
import 'screens/inventory/inventory_screen.dart';
import 'screens/customers/customer_list_screen.dart';
import 'screens/expenses/expense_list_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MandhoobApp());
}

class MandhoobApp extends StatelessWidget {
  const MandhoobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLanguage(),
      builder: (context, _) {
        final lang = AppLanguage();
        return MaterialApp(
          title: lang.isArabic
              ? 'مندوب - نظام المبيعات والتوزيع المتوافق مع هيئة الزكاة (ZATCA)'
              : 'M-Andhoob - ZATCA-Compliant Van Sales ERP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            return Directionality(
              textDirection: lang.textDirection,
              child: child!,
            );
          },
          home: const MainNavigationScreen(),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  String _getTitleForIndex(int index) {
    final lang = AppLanguage();
    switch (index) {
      case 0:
        return lang.isArabic ? 'مندوب (الرئيسية)' : 'M-Andhoob (Dashboard)';
      case 1:
        return lang.translate('sales');
      case 2:
        return lang.translate('purchases');
      case 3:
        return lang.translate('inventory');
      case 4:
        return lang.translate('customers');
      case 5:
        return lang.translate('expenses');
      case 6:
        return lang.translate('reports');
      case 7:
        return lang.translate('settings');
      default:
        return 'مندوب - Mandhoob';
    }
  }

  Widget _getScreenForIndex(int index) {
    final auth = AuthService();
    switch (index) {
      case 0:
        return DashboardScreen(
          onNavigateToSales: () => setState(() => _currentIndex = 1),
          onNavigateToInventory: () => setState(() => _currentIndex = 3),
          onNavigateToCustomers: () => setState(() => _currentIndex = 4),
        );
      case 1:
        return const SalesListScreen();
      case 2:
        if (!auth.can((p) => p.canCreatePurchase)) {
          return AccessDeniedWidget(
            requiredPermissionName: 'canCreatePurchase',
            customMessage: 'لا تمتلك صلاحية إدارة المشتريات والموردين. يتطلب هذا القسم دور المشرف أو المحاسب.',
            onReturnHome: () => setState(() => _currentIndex = 0),
          );
        }
        return const PurchaseListScreen();
      case 3:
        return const InventoryScreen();
      case 4:
        return const CustomerListScreen();
      case 5:
        if (!auth.can((p) => p.canManageExpenses)) {
          return AccessDeniedWidget(
            requiredPermissionName: 'canManageExpenses',
            customMessage: 'لا تمتلك صلاحية إدارة وتدقيق المصروفات التشغيلية والعهدة.',
            onReturnHome: () => setState(() => _currentIndex = 0),
          );
        }
        return const ExpenseListScreen();
      case 6:
        if (!auth.can((p) => p.canViewReports)) {
          return AccessDeniedWidget(
            requiredPermissionName: 'canViewReports',
            customMessage: 'التقارير المالية والضريبية مقيدة بالمحاسبين ومدراء النظام فقط.',
            onReturnHome: () => setState(() => _currentIndex = 0),
          );
        }
        return const ReportsScreen();
      case 7:
        return const SettingsScreen();
      default:
        return DashboardScreen(
          onNavigateToSales: () => setState(() => _currentIndex = 1),
          onNavigateToInventory: () => setState(() => _currentIndex = 3),
          onNavigateToCustomers: () => setState(() => _currentIndex = 4),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      currentIndex: _currentIndex,
      onNavigationIndexChanged: (index) {
        setState(() => _currentIndex = index);
      },
      title: _getTitleForIndex(_currentIndex),
      body: _getScreenForIndex(_currentIndex),
    );
  }
}

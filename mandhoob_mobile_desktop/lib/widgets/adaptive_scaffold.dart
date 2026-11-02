import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../models/user_model.dart';
import '../screens/search/global_search_screen.dart';

class AdaptiveScaffold extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigationIndexChanged;
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onNavigationIndexChanged,
    required this.body,
    required this.title,
    this.actions,
    this.floatingActionButton,
  });

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth >= 800;
    final isCompact = screenWidth < 600;

    return ListenableBuilder(
      listenable: AppLanguage(),
      builder: (context, _) {
        final lang = AppLanguage();

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            titleSpacing: isCompact ? 12 : null,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Cloud Sync Indicator
                ListenableBuilder(
                  listenable: SyncService(),
                  builder: (context, _) {
                    final sync = SyncService();
                    Color color = Colors.greenAccent;
                    String text = lang.isArabic ? 'متزامن' : 'Online';
                    IconData icon = Icons.cloud_done;

                    if (sync.isOffline) {
                      color = Colors.amberAccent;
                      text = lang.isArabic ? 'أوفلاين' : 'Offline';
                      icon = Icons.cloud_off;
                    } else if (sync.status == SyncStatus.syncing) {
                      color = Colors.cyanAccent;
                      text = lang.isArabic ? 'مزامنة' : 'Syncing';
                      icon = Icons.sync;
                    }

                    return Tooltip(
                      message: sync.isOffline
                          ? (lang.isArabic ? 'الوضع غير المتصل (Offline)' : 'Offline Mode')
                          : (lang.isArabic ? 'متزامن مع السحابة' : 'Synced with Cloud'),
                      child: InkWell(
                        onTap: () => sync.toggleOfflineMode(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 14, color: color),
                              if (!isCompact) ...[
                                const SizedBox(width: 4),
                                Text(
                                  text,
                                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                                ),
                              ],
                              if (sync.pendingChangesCount > 0) ...[
                                const SizedBox(width: 4),
                                CircleAvatar(
                                  radius: 7,
                                  backgroundColor: Colors.redAccent,
                                  child: Text(
                                    '${sync.pendingChangesCount}',
                                    style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              // Language Switcher Toggle (Compact on mobile)
              Tooltip(
                message: lang.isArabic ? 'Switch to English' : 'التحويل إلى العربية',
                child: InkWell(
                  onTap: () {
                    lang.toggleLanguage();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          lang.isArabic ? 'تم تغيير اللغة إلى العربية' : 'Language switched to English',
                        ),
                        duration: const Duration(milliseconds: 900),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: isCompact ? 7 : 10, vertical: 5),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language, size: 15, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          isCompact
                              ? (lang.isArabic ? 'EN' : 'عربي')
                              : (lang.isArabic ? 'English' : 'العربية'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Global Search Icon
              IconButton(
                icon: const Icon(Icons.search, size: 21),
                padding: isCompact ? const EdgeInsets.all(6) : null,
                constraints: isCompact ? const BoxConstraints(minWidth: 36, minHeight: 36) : null,
                tooltip: lang.isArabic ? 'البحث الشامل' : 'Global Search',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
                  );
                },
              ),

              // Role Switcher Button
              ListenableBuilder(
                listenable: AuthService(),
                builder: (context, _) {
                  final auth = AuthService();
                  return PopupMenuButton<UserRole>(
                    tooltip: lang.isArabic ? 'تغيير الصلاحية / Role' : 'Switch Role',
                    initialValue: auth.currentRole,
                    onSelected: (role) => auth.switchRole(role),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: UserRole.superAdmin,
                        child: Row(
                          children: [
                            const Icon(Icons.admin_panel_settings, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(lang.isArabic ? 'المدير العام (Super Admin)' : 'Super Admin'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: UserRole.admin,
                        child: Row(
                          children: [
                            const Icon(Icons.security, color: Colors.purple),
                            const SizedBox(width: 8),
                            Text(lang.isArabic ? 'مدير النظام (Admin)' : 'Admin'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: UserRole.salesman,
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(lang.isArabic ? 'مندوب مبيعات (Van Sales)' : 'Van Salesman'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: UserRole.accountant,
                        child: Row(
                          children: [
                            const Icon(Icons.calculate, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(lang.isArabic ? 'محاسب (Accountant)' : 'Accountant'),
                          ],
                        ),
                      ),
                    ],
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isCompact ? 4.0 : 8.0),
                      child: isCompact
                          ? Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                auth.currentRole == UserRole.salesman
                                    ? Icons.directions_car
                                    : (auth.currentRole == UserRole.superAdmin
                                        ? Icons.admin_panel_settings
                                        : Icons.badge),
                                size: 18,
                                color: AppColors.primary,
                              ),
                            )
                          : Chip(
                              avatar: Icon(
                                auth.currentRole == UserRole.salesman ? Icons.directions_car : Icons.badge,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              label: Text(
                                lang.isArabic
                                    ? auth.currentUser.roleDisplayNameAr.split(' ')[0]
                                    : auth.currentUser.role.name.toUpperCase(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ),
                    ),
                  );
                },
              ),

              if (widget.actions != null) ...widget.actions!,
            ],
          ),
          body: isDesktopOrTablet
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: widget.currentIndex,
                      onDestinationSelected: widget.onNavigationIndexChanged,
                      labelType: NavigationRailLabelType.all,
                      selectedIconTheme: const IconThemeData(color: AppColors.primary),
                      selectedLabelTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.dashboard_outlined),
                          selectedIcon: const Icon(Icons.dashboard),
                          label: Text(lang.translate('dashboard')),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.point_of_sale_outlined),
                          selectedIcon: const Icon(Icons.point_of_sale),
                          label: Text(lang.translate('sales')),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.shopping_bag_outlined),
                          selectedIcon: const Icon(Icons.shopping_bag),
                          label: Text(lang.translate('purchases')),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.inventory_2_outlined),
                          selectedIcon: const Icon(Icons.inventory_2),
                          label: Text(lang.translate('inventory')),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.people_alt_outlined),
                          selectedIcon: const Icon(Icons.people_alt),
                          label: Text(lang.translate('customers')),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.receipt_long_outlined),
                          selectedIcon: const Icon(Icons.receipt_long),
                          label: Text(lang.translate('expenses')),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.bar_chart_outlined),
                          selectedIcon: const Icon(Icons.bar_chart),
                          label: Text(lang.translate('reports')),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.settings_outlined),
                          selectedIcon: const Icon(Icons.settings),
                          label: Text(lang.translate('settings')),
                        ),
                      ],
                    ),
                    const VerticalDivider(thickness: 1, width: 1, color: AppColors.cardBorder),
                    Expanded(child: widget.body),
                  ],
                )
              : widget.body,
          bottomNavigationBar: isDesktopOrTablet
              ? null
              : NavigationBarTheme(
                  data: NavigationBarThemeData(
                    height: 64,
                    backgroundColor: Colors.white,
                    elevation: 8,
                    indicatorColor: AppColors.primary.withOpacity(0.12),
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        );
                      }
                      return const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: AppColors.textSecondary,
                      );
                    }),
                  ),
                  child: NavigationBar(
                    selectedIndex: widget.currentIndex > 4 ? 4 : widget.currentIndex,
                    onDestinationSelected: (index) {
                      if (index == 4) {
                        _showMoreMenu(context);
                      } else {
                        widget.onNavigationIndexChanged(index);
                      }
                    },
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.home_outlined),
                        selectedIcon: const Icon(Icons.home, color: AppColors.primary),
                        label: lang.translate('nav_home'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.point_of_sale_outlined),
                        selectedIcon: const Icon(Icons.point_of_sale, color: AppColors.primary),
                        label: lang.translate('nav_sales'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.inventory_2_outlined),
                        selectedIcon: const Icon(Icons.inventory_2, color: AppColors.primary),
                        label: lang.translate('nav_inventory'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.people_outline),
                        selectedIcon: const Icon(Icons.people, color: AppColors.primary),
                        label: lang.translate('nav_customers'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.grid_view_outlined),
                        selectedIcon: const Icon(Icons.grid_view, color: AppColors.primary),
                        label: lang.translate('nav_more'),
                      ),
                    ],
                  ),
                ),
          floatingActionButton: widget.floatingActionButton,
        );
      },
    );
  }

  void _showMoreMenu(BuildContext context) {
    final lang = AppLanguage();
    final auth = AuthService();
    final canPurchases = auth.can((p) => p.canCreatePurchase);
    final canExpenses = auth.can((p) => p.canManageExpenses);
    final canReports = auth.can((p) => p.canViewReports);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(top: 14, bottom: 28, left: 16, right: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  lang.isArabic ? 'الأقسام الإضافية والعمليات' : 'More Modules & Operations',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: canPurchases ? AppColors.purchaseBlue.withOpacity(0.12) : Colors.grey.shade200,
                    child: Icon(
                      canPurchases ? Icons.shopping_bag : Icons.lock_outline,
                      color: canPurchases ? AppColors.purchaseBlue : Colors.grey.shade600,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(lang.translate('purchases'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (!canPurchases) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            lang.isArabic ? 'صلاحية مقيدة' : 'Restricted',
                            style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(lang.isArabic ? 'إدارة الموردين وأوامر الشراء' : 'Suppliers & Purchase Invoices'),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onNavigationIndexChanged(2);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: canExpenses ? AppColors.expenseRed.withOpacity(0.12) : Colors.grey.shade200,
                    child: Icon(
                      canExpenses ? Icons.receipt_long : Icons.lock_outline,
                      color: canExpenses ? AppColors.expenseRed : Colors.grey.shade600,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(lang.translate('expenses'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (!canExpenses) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            lang.isArabic ? 'صلاحية مقيدة' : 'Restricted',
                            style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(lang.isArabic ? 'مصروفات السيارة والمحروقات والعهدة' : 'Van Running, Fuel & Daily Expenses'),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onNavigationIndexChanged(5);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: canReports ? Colors.purple.withOpacity(0.12) : Colors.grey.shade200,
                    child: Icon(
                      canReports ? Icons.bar_chart : Icons.lock_outline,
                      color: canReports ? Colors.purple : Colors.grey.shade600,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(lang.translate('reports'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (!canReports) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            lang.isArabic ? 'صلاحية مقيدة' : 'Restricted',
                            style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(lang.isArabic ? 'إقرار الزكاة ZATCA وأعمار الديون' : 'ZATCA Tax Return & Aging Reports'),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onNavigationIndexChanged(6);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueGrey.withOpacity(0.12),
                    child: const Icon(Icons.settings, color: Colors.blueGrey),
                  ),
                  title: Text(lang.translate('settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(lang.isArabic ? 'تهيئة المنشأة والربط والطابعة' : 'Company Profile, ZATCA & Bluetooth Printer'),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onNavigationIndexChanged(7);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

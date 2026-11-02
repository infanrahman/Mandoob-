import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';
import '../../models/warehouse_model.dart';
import '../../models/stock_transfer_model.dart';
import '../../models/stock_adjustment_model.dart';
import '../../models/user_model.dart';
import '../../widgets/date_filter_bar.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'ALL';

  String _transferSearchQuery = '';
  DateFilterPreset _transferDatePreset = DateFilterPreset.all;
  DateTimeRange? _transferCustomRange;

  String _adjSearchQuery = '';
  DateFilterPreset _adjDatePreset = DateFilterPreset.all;
  DateTimeRange? _adjCustomRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AppLanguage()]),
      builder: (context, _) {
        final db = DatabaseService();
        final lang = AppLanguage();
        final auth = AuthService();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';
        final isSalesman = auth.currentUser.role == UserRole.salesman;

        // KPI Calculations
        final totalInventoryValue = db.products.fold<double>(
          0.0,
          (sum, p) => sum + (p.getTotalStock() * p.wholesalePrice),
        );
        final lowStockCount = db.products.where((p) => p.getTotalStock() <= p.minStockAlert).length;
        final nearExpiryCount = db.products.where((p) => p.isExpiringSoon).length;

        return Scaffold(
          body: Column(
            children: [
              // Sleek Modern TabBar Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        tabAlignment: TabAlignment.start,
                        tabs: [
                          Tab(
                            icon: const Icon(Icons.inventory_2_outlined, size: 18),
                            text: lang.isArabic ? 'أرصدة الأصناف' : 'Stock Levels',
                          ),
                          Tab(
                            icon: const Icon(Icons.local_shipping_outlined, size: 18),
                            text: lang.isArabic ? 'بضاعة السيارات' : 'Van Inventory',
                          ),
                          Tab(
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            text: lang.isArabic ? 'سجل التحميل والنقل' : 'Transfers Log',
                          ),
                          Tab(
                            icon: const Icon(Icons.fact_check_outlined, size: 18),
                            text: lang.isArabic ? 'تسويات الجرد' : 'Adjustments',
                          ),
                        ],
                      ),
                    ),
                    if (auth.can((p) => p.canManageInventory)) ...[
                      IconButton(
                        icon: const Icon(Icons.add_box_outlined, color: AppColors.primary),
                        tooltip: lang.isArabic ? 'إضافة صنف جديد' : 'Add Product',
                        onPressed: () => _showAddOrEditProductDialog(context, null, lang, db),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune, color: AppColors.primary),
                        tooltip: lang.isArabic ? 'تسوية جردية' : 'Stock Adjustment',
                        onPressed: () => _showStockAdjustmentDialog(context, null, lang, db, auth),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
              // Inventory Quick Summary Dashboard Banner
              _buildSummaryHeader(
                totalItems: db.products.length,
                totalValue: totalInventoryValue,
                lowStockCount: lowStockCount,
                nearExpiryCount: nearExpiryCount,
                curr: curr,
                lang: lang,
                isSalesman: isSalesman,
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProductsStockTab(db, lang, auth, curr),
                    _buildVansStockTab(db, lang, auth, curr),
                    _buildTransfersLogTab(db, lang, curr),
                    _buildAdjustmentsLogTab(db, lang),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: auth.can((p) => p.canManageInventory)
              ? (_tabController.index == 0
                  ? FloatingActionButton.extended(
                      onPressed: () => _showAddOrEditProductDialog(context, null, lang, db),
                      backgroundColor: AppColors.primary,
                      elevation: 4,
                      icon: const Icon(Icons.add, color: Colors.white, size: 20),
                      label: Text(
                        lang.isArabic ? 'إضافة صنف جديد' : '+ Add Product',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    )
                  : (_tabController.index == 3
                      ? FloatingActionButton.extended(
                          onPressed: () => _showStockAdjustmentDialog(context, null, lang, db, auth),
                          backgroundColor: Colors.teal.shade700,
                          elevation: 4,
                          icon: const Icon(Icons.tune, color: Colors.white, size: 20),
                          label: Text(
                            lang.isArabic ? 'تسوية جردية' : '+ Stock Adjustment',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        )
                      : FloatingActionButton.extended(
                          onPressed: () => _showStockTransferDialog(context, lang, db, auth),
                          backgroundColor: AppColors.primary,
                          elevation: 4,
                          icon: const Icon(Icons.move_to_inbox, color: Colors.white, size: 20),
                          label: Text(
                            lang.isArabic ? 'نقل / تحميل بضاعة' : '+ Transfer Stock',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        )))
              : null,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Top Summary Dashboard Banner
  // ---------------------------------------------------------------------------
  Widget _buildSummaryHeader({
    required int totalItems,
    required double totalValue,
    required int lowStockCount,
    required int nearExpiryCount,
    required String curr,
    required AppLanguage lang,
    required bool isSalesman,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildHeaderMetric(
              label: lang.isArabic ? 'إجمالي الأصناف' : 'Total Items',
              value: '$totalItems',
              icon: Icons.grid_view,
              color: Colors.white,
            ),
          ),
          if (!isSalesman) ...[
            Container(width: 1, height: 28, color: Colors.white24),
            Expanded(
              child: _buildHeaderMetric(
                label: lang.isArabic ? 'قيمة المخزون' : 'Stock Value',
                value: '${totalValue.toStringAsFixed(0)} $curr',
                icon: Icons.account_balance_wallet_outlined,
                color: Colors.greenAccent,
              ),
            ),
          ],
          Container(width: 1, height: 28, color: Colors.white24),
          Expanded(
            child: _buildHeaderMetric(
              label: lang.isArabic ? 'أوشك على النفاد' : 'Low Stock',
              value: '$lowStockCount',
              icon: Icons.warning_amber_rounded,
              color: lowStockCount > 0 ? Colors.amberAccent : Colors.white70,
            ),
          ),
          Container(width: 1, height: 28, color: Colors.white24),
          Expanded(
            child: _buildHeaderMetric(
              label: lang.isArabic ? 'قريب الانتهاء' : 'Near Expiry',
              value: '$nearExpiryCount',
              icon: Icons.schedule,
              color: nearExpiryCount > 0 ? Colors.redAccent.shade100 : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: All Products Stock with Search, Categories, and Quick Actions
  // ---------------------------------------------------------------------------
  Widget _buildProductsStockTab(DatabaseService db, AppLanguage lang, AuthService auth, String curr) {
    // Unique categories
    final categories = <String>{'ALL'};
    for (final p in db.products) {
      categories.add(p.category);
    }

    final filtered = db.products.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = p.nameAr.toLowerCase().contains(q) ||
            p.nameEn.toLowerCase().contains(q) ||
            p.barcode.contains(q) ||
            p.sku.toLowerCase().contains(q);
        if (!match) return false;
      }
      if (_selectedCategory == 'LOW_STOCK') {
        return p.getTotalStock() <= p.minStockAlert;
      }
      if (_selectedCategory == 'EXPIRING_SOON') {
        return p.isExpiringSoon;
      }
      if (_selectedCategory != 'ALL' && p.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search & Category Filters
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: lang.isArabic
                      ? 'البحث باسم الصنف، الباركود أو الرمز (SKU)...'
                      : 'Search by item name, barcode or SKU...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _searchQuery = ''))
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', lang.isArabic ? 'الكل' : 'All'),
                    const SizedBox(width: 6),
                    _buildFilterChip('LOW_STOCK', lang.isArabic ? 'أوشك على النفاد ⚠️' : 'Low Stock ⚠️', isAlert: true),
                    const SizedBox(width: 6),
                    _buildFilterChip('EXPIRING_SOON', lang.isArabic ? 'قريب الانتهاء ⏳' : 'Near Expiry ⏳', isAlert: true),
                    ...categories.where((c) => c != 'ALL').map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _buildFilterChip(cat, cat.split(' - ')[0]),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Products List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text(
                        lang.isArabic ? 'لا توجد أصناف تطابق معايير البحث' : 'No items match your search filter',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () => _showAddOrEditProductDialog(context, null, lang, db),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(lang.isArabic ? 'إضافة صنف جديد' : 'Add New Item'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final prod = filtered[index];
                    final totalStock = prod.getTotalStock();
                    final mainStock = prod.getStockFor('WH-MAIN');
                    final isLow = totalStock <= prod.minStockAlert;
                    final isExpiring = prod.isExpiringSoon;

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 0.5,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isLow ? Colors.red.shade200 : AppColors.cardBorder,
                            width: isLow ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Product Name + Total Stock Badge + Action Menu
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lang.isArabic ? prod.nameAr : prod.nameEn,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${lang.isArabic ? "الباركود" : "Barcode"}: ${prod.barcode} • ${lang.isArabic ? "الرمز" : "SKU"}: ${prod.sku}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isLow ? Colors.red.shade50 : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isLow ? Colors.red.shade200 : Colors.green.shade200),
                                  ),
                                  child: Text(
                                    '${totalStock.toInt()} ${prod.baseUnit.split(" - ")[0]}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isLow ? Colors.red.shade800 : Colors.green.shade800,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      _showAddOrEditProductDialog(context, prod, lang, db);
                                    } else if (val == 'adjust') {
                                      _showStockAdjustmentDialog(context, prod, lang, db, auth);
                                    } else if (val == 'transfer') {
                                      _showStockTransferDialog(context, lang, db, auth, preselectedProduct: prod);
                                    } else if (val == 'delete') {
                                      _confirmDeleteProduct(context, prod, lang, db);
                                    }
                                  },
                                  itemBuilder: (ctx) {
                                    final items = <PopupMenuEntry<String>>[];
                                    if (auth.can((p) => p.canManageInventory)) {
                                      items.add(
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.edit, size: 18, color: AppColors.primary),
                                              const SizedBox(width: 8),
                                              Text(lang.isArabic ? 'تعديل الصنف والأسعار' : 'Edit Product'),
                                            ],
                                          ),
                                        ),
                                      );
                                      items.add(
                                        PopupMenuItem(
                                          value: 'adjust',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.tune, size: 18, color: Colors.orange),
                                              const SizedBox(width: 8),
                                              Text(lang.isArabic ? 'تسوية جردية (جرد فعلي)' : 'Adjust Stock'),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    if (auth.can((p) => p.canTransferVanStock)) {
                                      items.add(
                                        PopupMenuItem(
                                          value: 'transfer',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.move_to_inbox, size: 18, color: Colors.teal),
                                              const SizedBox(width: 8),
                                              Text(lang.isArabic ? 'نقل وتحميل للسيارة' : 'Transfer Stock'),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    if (auth.can((p) => p.canManageInventory && (p.canDeleteSale || p.canResetSystemData))) {
                                      items.add(const PopupMenuDivider());
                                      items.add(
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.delete_outline, size: 18, color: AppColors.expenseRed),
                                              const SizedBox(width: 8),
                                              Text(lang.isArabic ? 'حذف الصنف' : 'Delete', style: const TextStyle(color: AppColors.expenseRed)),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    return items;
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 16),

                            // Multi-Warehouse Distribution
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${lang.isArabic ? "المستودع الرئيسي" : "Main Warehouse"}: ${mainStock.toInt()} ${prod.baseUnit.split(" - ")[0]}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${lang.isArabic ? "سعر التجزئة" : "Retail"}: ${prod.retailPrice.toStringAsFixed(2)} $curr',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          spacing: 12,
                                          runSpacing: 4,
                                          children: db.warehouses.where((w) => w.isVan).map((van) {
                                            final vStock = prod.getStockFor(van.id);
                                            return Text(
                                              '${van.nameAr.split(" - ")[0]}: ${vStock.toInt()}',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      if (auth.can((p) => p.canViewProfitAndCost))
                                        Text(
                                          '${lang.isArabic ? "الجملة" : "Wholesale"}: ${prod.wholesalePrice.toStringAsFixed(2)} $curr',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Batch & Expiry and Alerts
                            if (prod.batchNumber != null || isExpiring || isLow) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (prod.batchNumber != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.qr_code, size: 12, color: AppColors.textMuted),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${lang.isArabic ? "التشغيلة" : "Batch"}: ${prod.batchNumber}',
                                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  if (prod.expiryDate != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 12,
                                          color: isExpiring ? Colors.red : AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${lang.isArabic ? "الانتهاء" : "Expiry"}: ${prod.expiryDate.toString().substring(0, 10)}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: isExpiring ? FontWeight.bold : FontWeight.normal,
                                            color: isExpiring ? Colors.red.shade800 : AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (isLow)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        lang.isArabic ? 'تنبيه: أوشك على النفاد!' : 'Alert: Low Stock!',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, {bool isAlert = false}) {
    final isSelected = _selectedCategory == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: isAlert ? Colors.amber.shade200 : AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? (isAlert ? Colors.black87 : Colors.white) : AppColors.textSecondary,
      ),
      onSelected: (_) => setState(() => _selectedCategory = key),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Van-Specific Stock Breakdown with Unload & Load Actions
  // ---------------------------------------------------------------------------
  Widget _buildVansStockTab(DatabaseService db, AppLanguage lang, AuthService auth, String curr) {
    final vans = db.warehouses.where((w) => w.isVan).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: vans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final van = vans[index];
        final vanTotalValue = db.getVanStockValue(van.id);
        final loadedItems = db.products.where((p) => (p.stockByWarehouse[van.id] ?? 0) > 0).toList();

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Van Info Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFEFF6FF),
                            child: Icon(Icons.directions_car, color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.isArabic ? van.nameAr : van.nameEn,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${lang.isArabic ? "السائق" : "Driver"}: ${van.assignedDriverName ?? "-"} • ${lang.isArabic ? "اللوحة" : "Plate"}: ${van.vehiclePlateNumber ?? "-"}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${vanTotalValue.toStringAsFixed(2)} $curr',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.saleGreen),
                        ),
                        Text(
                          lang.isArabic ? 'قيمة البضاعة' : 'Stock Value',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Loaded Products List
                Text(
                  '${lang.isArabic ? "الأصناف المحملة في السيارة" : "Items Currently in Van"} (${loadedItems.length}):',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),

                if (loadedItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      lang.isArabic ? 'السيارة فارغة حالياً، لم يتم تحميل بضاعة' : 'Van is empty, no stock loaded',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: loadedItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 10),
                    itemBuilder: (ctx, i) {
                      final p = loadedItems[i];
                      final qty = p.stockByWarehouse[van.id] ?? 0.0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              lang.isArabic ? p.nameAr : p.nameEn,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${qty.toInt()} ${p.baseUnit.split(" - ")[0]}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                          ),
                        ],
                      );
                    },
                  ),

                const SizedBox(height: 14),

                // Van Stock Actions: Morning Load & Evening Return
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showStockTransferDialog(
                          context,
                          lang,
                          db,
                          auth,
                          preselectedToWarehouseId: van.id,
                        ),
                        icon: const Icon(Icons.arrow_upward, size: 16),
                        label: Text(lang.isArabic ? 'تحميل بضاعة للسيارة' : 'Load Van Stock'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.saleGreen,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: loadedItems.isEmpty
                            ? null
                            : () => _showEveningVanReturnDialog(context, van, loadedItems, lang, db, auth),
                        icon: const Icon(Icons.arrow_downward, size: 16),
                        label: Text(lang.isArabic ? 'تفريغ واسترجاع المساء' : 'Evening Return'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Stock Transfers Log
  // ---------------------------------------------------------------------------
  Widget _buildTransfersLogTab(DatabaseService db, AppLanguage lang, String curr) {
    final filteredTransfers = db.stockTransfers.where((trf) {
      if (!DateFilterHelper.matches(trf.date, _transferDatePreset, _transferCustomRange)) {
        return false;
      }
      if (_transferSearchQuery.isNotEmpty) {
        final q = _transferSearchQuery.toLowerCase().trim();
        final matchNum = trf.transferNumber.toLowerCase().contains(q);
        final matchFrom = trf.fromWarehouseName.toLowerCase().contains(q);
        final matchTo = trf.toVanName.toLowerCase().contains(q);
        final matchUser = trf.requestedByUserName.toLowerCase().contains(q);
        final matchItems = trf.items.any((it) => it.productName.toLowerCase().contains(q));
        return matchNum || matchFrom || matchTo || matchUser || matchItems;
      }
      return true;
    }).toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: lang.isArabic
                      ? 'ابحث برقم النقل أو المستودع أو الصنف...'
                      : 'Search transfer #, warehouse, item...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.teal),
                  suffixIcon: _transferSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => setState(() => _transferSearchQuery = ''),
                        )
                      : null,
                  fillColor: Colors.grey.shade100,
                  filled: true,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _transferSearchQuery = val),
              ),
              const SizedBox(height: 6),
              DateFilterBar(
                selectedPreset: _transferDatePreset,
                customRange: _transferCustomRange,
                onPresetChanged: (preset) => setState(() => _transferDatePreset = preset),
                onCustomRangeChanged: (range) => setState(() => _transferCustomRange = range),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filteredTransfers.isEmpty
              ? Center(
                  child: Text(
                    lang.isArabic ? 'لا توجد حركات نقل مطابقة للبحث والتاريخ' : 'No stock transfers match search',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: filteredTransfers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final trf = filteredTransfers[index];
                    final totalItemsCount = trf.items.fold<double>(0.0, (s, it) => s + it.quantity);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.teal.shade50,
                                  child: const Icon(Icons.sync_alt, color: Colors.teal, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${trf.fromWarehouseName} ➔ ${trf.toVanName}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${trf.transferNumber} • ${trf.date.toLocal().toString().substring(0, 16)}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    lang.isArabic ? 'تم النقل' : 'Completed',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: trf.items.map((it) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Text(
                                    '${it.productName}: ${it.quantity.toInt()} ${it.unit}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (trf.notes != null && trf.notes!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '${lang.isArabic ? "ملاحظات" : "Notes"}: ${trf.notes} • ${lang.isArabic ? "المسؤول" : "By"}: ${trf.requestedByUserName}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 4: Physical Stock Adjustments Audit Log
  // ---------------------------------------------------------------------------
  Widget _buildAdjustmentsLogTab(DatabaseService db, AppLanguage lang) {
    final filteredAdjustments = db.stockAdjustments.where((adj) {
      if (!DateFilterHelper.matches(adj.date, _adjDatePreset, _adjCustomRange)) {
        return false;
      }
      if (_adjSearchQuery.isNotEmpty) {
        final q = _adjSearchQuery.toLowerCase().trim();
        final matchNum = adj.adjustmentNumber.toLowerCase().contains(q);
        final matchProd = adj.productNameAr.toLowerCase().contains(q) || adj.productNameEn.toLowerCase().contains(q);
        final matchWh = adj.warehouseName.toLowerCase().contains(q);
        final matchUser = adj.adjustedByUserName.toLowerCase().contains(q);
        return matchNum || matchProd || matchWh || matchUser;
      }
      return true;
    }).toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: lang.isArabic
                      ? 'ابحث برقم التسوية أو اسم الصنف أو المستودع...'
                      : 'Search adjustment #, product, warehouse...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.orange),
                  suffixIcon: _adjSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => setState(() => _adjSearchQuery = ''),
                        )
                      : null,
                  fillColor: Colors.grey.shade100,
                  filled: true,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _adjSearchQuery = val),
              ),
              const SizedBox(height: 6),
              DateFilterBar(
                selectedPreset: _adjDatePreset,
                customRange: _adjCustomRange,
                onPresetChanged: (preset) => setState(() => _adjDatePreset = preset),
                onCustomRangeChanged: (range) => setState(() => _adjCustomRange = range),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filteredAdjustments.isEmpty
              ? Center(
                  child: Text(
                    lang.isArabic ? 'لا توجد تسويات جردية مطابقة' : 'No adjustments match search',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: filteredAdjustments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final adj = filteredAdjustments[index];
                    final isNegative = adj.differenceQuantity < 0;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isNegative ? Colors.red.shade50 : Colors.green.shade50,
                                  child: Icon(
                                    isNegative ? Icons.remove : Icons.add,
                                    color: isNegative ? AppColors.expenseRed : AppColors.saleGreen,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lang.isArabic ? adj.productNameAr : adj.productNameEn,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${adj.adjustmentNumber} • ${adj.warehouseName}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isNegative ? Colors.red.shade50 : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${isNegative ? "" : "+"}${adj.differenceQuantity.toInt()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isNegative ? AppColors.expenseRed : Colors.green.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${lang.isArabic ? "الرصيد السابق" : "Prev"}: ${adj.previousQuantity.toInt()} ➔ ${lang.isArabic ? "الفعلي الجديد" : "New"}: ${adj.newQuantity.toInt()}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Text(
                                    adj.reasonDisplayName(lang.isArabic),
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                            if (adj.notes != null && adj.notes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${lang.isArabic ? "ملاحظات" : "Note"}: ${adj.notes} • ${adj.adjustedByUserName}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Modal: Add or Edit Product
  // ---------------------------------------------------------------------------
  void _showAddOrEditProductDialog(BuildContext context, ProductModel? existing, AppLanguage lang, DatabaseService db) {
    final formKey = GlobalKey<FormState>();
    final nameArCtrl = TextEditingController(text: existing?.nameAr ?? '');
    final nameEnCtrl = TextEditingController(text: existing?.nameEn ?? '');
    final skuCtrl = TextEditingController(text: existing?.sku ?? 'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final barcodeCtrl = TextEditingController(text: existing?.barcode ?? '628${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}');
    final categoryCtrl = TextEditingController(text: existing?.category ?? 'ألبان - Dairy');
    final baseUnitCtrl = TextEditingController(text: existing?.baseUnit ?? 'حبة - Piece');
    final costPriceCtrl = TextEditingController(text: existing != null ? existing.costPrice.toStringAsFixed(2) : '5.00');
    final wholesalePriceCtrl = TextEditingController(text: existing != null ? existing.wholesalePrice.toStringAsFixed(2) : '6.50');
    final retailPriceCtrl = TextEditingController(text: existing != null ? existing.retailPrice.toStringAsFixed(2) : '8.00');
    final minStockCtrl = TextEditingController(text: existing != null ? existing.minStockAlert.toStringAsFixed(0) : '20');
    final batchCtrl = TextEditingController(text: existing?.batchNumber ?? 'B-${DateTime.now().year}-01');
    final initialStockCtrl = TextEditingController(text: existing != null ? existing.getStockFor('WH-MAIN').toStringAsFixed(0) : '100');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final mediaQuery = MediaQuery.of(ctx);
        final keyboard = mediaQuery.viewInsets.bottom;
        final systemBottom = mediaQuery.viewPadding.bottom;

        return SafeArea(
          top: false,
          bottom: true,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 14,
              bottom: keyboard > 0 ? keyboard + 16 : (systemBottom > 0 ? systemBottom + 12 : 28),
            ),
            constraints: BoxConstraints(
              maxHeight: mediaQuery.size.height * 0.9,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing != null
                            ? (lang.isArabic ? 'تعديل بيانات الصنف' : 'Edit Product')
                            : (lang.isArabic ? 'إضافة صنف جديد' : 'Add New Product'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(height: 16),
                  TextFormField(
                    controller: nameArCtrl,
                    decoration: InputDecoration(
                      labelText: lang.isArabic ? 'اسم الصنف بالعربي *' : 'Product Name (Arabic) *',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? (lang.isArabic ? 'الحقل مطلوب' : 'Required') : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameEnCtrl,
                    decoration: InputDecoration(
                      labelText: lang.isArabic ? 'اسم الصنف بالإنجليزي *' : 'Product Name (English) *',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? (lang.isArabic ? 'الحقل مطلوب' : 'Required') : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: barcodeCtrl,
                          decoration: InputDecoration(
                            labelText: lang.isArabic ? 'الباركود' : 'Barcode',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: skuCtrl,
                          decoration: InputDecoration(
                            labelText: lang.isArabic ? 'الرمز (SKU)' : 'SKU',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: categoryCtrl,
                          decoration: InputDecoration(
                            labelText: lang.isArabic ? 'التصنيف' : 'Category',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: baseUnitCtrl,
                          decoration: InputDecoration(
                            labelText: lang.isArabic ? 'الوحدة' : 'Unit',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: costPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: lang.isArabic ? 'سعر التكلفة' : 'Cost Price',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: wholesalePriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: lang.isArabic ? 'سعر الجملة' : 'Wholesale',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: retailPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: lang.isArabic ? 'سعر التجزئة' : 'Retail',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: minStockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.isArabic ? 'تنبيه حد الطلب' : 'Min Alert Qty',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: initialStockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.isArabic ? 'المخزون الرئيسي' : 'Main Wh Stock',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final mainStock = double.tryParse(initialStockCtrl.text) ?? 100.0;
                          final prod = ProductModel(
                            id: existing?.id ?? 'PRD-${DateTime.now().millisecondsSinceEpoch}',
                            sku: skuCtrl.text.trim(),
                            barcode: barcodeCtrl.text.trim(),
                            nameAr: nameArCtrl.text.trim(),
                            nameEn: nameEnCtrl.text.trim(),
                            category: categoryCtrl.text.trim(),
                            baseUnit: baseUnitCtrl.text.trim(),
                            costPrice: double.tryParse(costPriceCtrl.text) ?? 5.0,
                            wholesalePrice: double.tryParse(wholesalePriceCtrl.text) ?? 6.5,
                            retailPrice: double.tryParse(retailPriceCtrl.text) ?? 8.0,
                            minStockAlert: double.tryParse(minStockCtrl.text) ?? 20.0,
                            stockByWarehouse: existing != null
                                ? {
                                    ...existing.stockByWarehouse,
                                    'WH-MAIN': mainStock,
                                  }
                                : {
                                    'WH-MAIN': mainStock,
                                    'VAN-01': 20.0,
                                    'VAN-02': 10.0,
                                  },
                            batchNumber: batchCtrl.text.trim(),
                            expiryDate: DateTime.now().add(const Duration(days: 90)),
                          );

                          if (existing != null) {
                            db.updateProduct(prod);
                          } else {
                            db.addProduct(prod);
                          }

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                existing != null
                                    ? (lang.isArabic ? 'تم تحديث بيانات الصنف بنجاح' : 'Product updated successfully')
                                    : (lang.isArabic ? 'تم إضافة الصنف الجديد بنجاح' : 'New product added successfully'),
                              ),
                              backgroundColor: AppColors.saleGreen,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: Text(
                        existing != null
                            ? (lang.isArabic ? 'حفظ التعديلات' : 'Save Changes')
                            : (lang.isArabic ? 'إضافة الصنف' : 'Save Product'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

  // ---------------------------------------------------------------------------
  // Modal: Stock Adjustment (تسوية جردية - جرد فعلي / تالف / منتهي)
  // ---------------------------------------------------------------------------
  void _showStockAdjustmentDialog(
    BuildContext context,
    ProductModel? targetProd,
    AppLanguage lang,
    DatabaseService db,
    AuthService auth,
  ) {
    ProductModel selectedProduct = targetProd ?? db.products.first;
    String selectedWarehouseId = 'WH-MAIN';
    AdjustmentReason selectedReason = AdjustmentReason.physicalCount;
    final currentQty = selectedProduct.getStockFor(selectedWarehouseId);
    final actualQtyCtrl = TextEditingController(text: currentQty.toStringAsFixed(0));
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final prevQty = selectedProduct.getStockFor(selectedWarehouseId);
            final newQty = double.tryParse(actualQtyCtrl.text) ?? prevQty;
            final diff = newQty - prevQty;
            final mediaQuery = MediaQuery.of(modalCtx);
            final keyboard = mediaQuery.viewInsets.bottom;
            final systemBottom = mediaQuery.viewPadding.bottom;

            return SafeArea(
              top: false,
              bottom: true,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 14,
                  bottom: keyboard > 0 ? keyboard + 16 : (systemBottom > 0 ? systemBottom + 12 : 28),
                ),
                constraints: BoxConstraints(
                  maxHeight: mediaQuery.size.height * 0.9,
                ),
                child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lang.isArabic ? 'تسوية جردية لمخزون الصنف' : 'Stock Adjustment & Physical Audit',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 16),
                    DropdownButtonFormField<ProductModel>(
                      isExpanded: true,
                      value: selectedProduct,
                      decoration: InputDecoration(
                        labelText: lang.isArabic ? 'اختر الصنف' : 'Select Product',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: db.products.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(lang.isArabic ? p.nameAr : p.nameEn, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (p) {
                        if (p != null) {
                          setModalState(() {
                            selectedProduct = p;
                            actualQtyCtrl.text = p.getStockFor(selectedWarehouseId).toStringAsFixed(0);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedWarehouseId,
                      decoration: InputDecoration(
                        labelText: lang.isArabic ? 'المستودع أو سيارة التوزيع' : 'Warehouse / Van',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: db.warehouses.map((w) {
                        return DropdownMenuItem(
                          value: w.id,
                          child: Text(lang.isArabic ? w.nameAr : w.nameEn, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (w) {
                        if (w != null) {
                          setModalState(() {
                            selectedWarehouseId = w;
                            actualQtyCtrl.text = selectedProduct.getStockFor(w).toStringAsFixed(0);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lang.isArabic ? 'الرصيد الدفتري الحالي' : 'System Stock Qty', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text('${prevQty.toInt()} ${selectedProduct.baseUnit.split(" - ")[0]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          const Icon(Icons.arrow_forward, color: AppColors.textMuted),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(lang.isArabic ? 'الفارق (العجز/الزيادة)' : 'Variance', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(
                                '${diff >= 0 ? "+" : ""}${diff.toInt()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: diff < 0 ? AppColors.expenseRed : (diff > 0 ? AppColors.saleGreen : AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: actualQtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: lang.isArabic ? 'الكمية الفعلية الجديدة بعد الجرد *' : 'Actual Counted Quantity *',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<AdjustmentReason>(
                      isExpanded: true,
                      value: selectedReason,
                      decoration: InputDecoration(
                        labelText: lang.isArabic ? 'سبب التسوية الجردية' : 'Adjustment Reason',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: AdjustmentReason.values.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(_reasonTitle(r, lang.isArabic)),
                        );
                      }).toList(),
                      onChanged: (r) {
                        if (r != null) setModalState(() => selectedReason = r);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        labelText: lang.isArabic ? 'ملاحظات وتفاصيل التسوية' : 'Adjustment Notes / Comments',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final finalQty = double.tryParse(actualQtyCtrl.text) ?? prevQty;
                          db.recordStockAdjustment(
                            productId: selectedProduct.id,
                            warehouseId: selectedWarehouseId,
                            newQuantity: finalQty,
                            reason: selectedReason,
                            notes: notesCtrl.text.trim(),
                            userId: auth.currentUser.id,
                            userName: auth.currentUser.name,
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(lang.isArabic ? 'تم حفظ تسوية الجرد وتحديث المخزون بنجاح' : 'Stock adjustment recorded successfully'),
                              backgroundColor: AppColors.saleGreen,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: Text(lang.isArabic ? 'اعتماد تسوية الجرد' : 'Confirm Stock Adjustment'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  String _reasonTitle(AdjustmentReason reason, bool isArabic) {
    switch (reason) {
      case AdjustmentReason.physicalCount:
        return isArabic ? 'جرد فعلي دوري' : 'Periodic Physical Count';
      case AdjustmentReason.damaged:
        return isArabic ? 'تالف ومكسور' : 'Damaged / Broken';
      case AdjustmentReason.expired:
        return isArabic ? 'منتهي الصلاحية' : 'Expired Stock';
      case AdjustmentReason.missing:
        return isArabic ? 'عجز / نقص في المستودع' : 'Missing / Shrinkage';
      case AdjustmentReason.sample:
        return isArabic ? 'عينات تسويقية' : 'Marketing Samples';
      case AdjustmentReason.other:
        return isArabic ? 'تسوية يدوية أخرى' : 'Other Adjustment';
    }
  }

  // ---------------------------------------------------------------------------
  // Modal: Multi-Item Stock Transfer Dialog (Main <-> Van / Van <-> Van)
  // ---------------------------------------------------------------------------
  void _showStockTransferDialog(
    BuildContext context,
    AppLanguage lang,
    DatabaseService db,
    AuthService auth, {
    ProductModel? preselectedProduct,
    String? preselectedToWarehouseId,
  }) {
    String fromWarehouseId = 'WH-MAIN';
    String toWarehouseId = preselectedToWarehouseId ?? (db.warehouses.where((w) => w.isVan).isNotEmpty ? db.warehouses.where((w) => w.isVan).first.id : 'WH-MAIN');
    ProductModel selectedProduct = preselectedProduct ?? db.products.first;
    double transferQty = 10.0;
    final notesCtrl = TextEditingController(text: lang.isArabic ? 'تحميل بضاعة من المستودع للسيارة' : 'Stock load to van');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final fromStock = selectedProduct.getStockFor(fromWarehouseId);
            final toStock = selectedProduct.getStockFor(toWarehouseId);
            final mediaQuery = MediaQuery.of(modalCtx);
            final keyboard = mediaQuery.viewInsets.bottom;
            final systemBottom = mediaQuery.viewPadding.bottom;

            return SafeArea(
              top: false,
              bottom: true,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 14,
                  bottom: keyboard > 0 ? keyboard + 16 : (systemBottom > 0 ? systemBottom + 12 : 28),
                ),
                constraints: BoxConstraints(
                  maxHeight: mediaQuery.size.height * 0.9,
                ),
                child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lang.isArabic ? 'سند تحويل بضاعة بين المستودعات والسيارات' : 'Stock Transfer Order',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: fromWarehouseId,
                            decoration: InputDecoration(
                              labelText: lang.isArabic ? 'من (المصدر)' : 'From (Source)',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: db.warehouses.map((w) {
                              return DropdownMenuItem(value: w.id, child: Text(w.nameAr.split(" - ")[0], overflow: TextOverflow.ellipsis));
                            }).toList(),
                            onChanged: (w) {
                              if (w != null) setModalState(() => fromWarehouseId = w);
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward, color: AppColors.primary, size: 20),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: toWarehouseId,
                            decoration: InputDecoration(
                              labelText: lang.isArabic ? 'إلى (الهدف)' : 'To (Destination)',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: db.warehouses.map((w) {
                              return DropdownMenuItem(value: w.id, child: Text(w.nameAr.split(" - ")[0], overflow: TextOverflow.ellipsis));
                            }).toList(),
                            onChanged: (w) {
                              if (w != null) setModalState(() => toWarehouseId = w);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ProductModel>(
                      isExpanded: true,
                      value: selectedProduct,
                      decoration: InputDecoration(
                        labelText: lang.isArabic ? 'اختر الصنف المراد تحويله' : 'Select Item to Transfer',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: db.products.map((p) {
                        return DropdownMenuItem(value: p, child: Text(lang.isArabic ? p.nameAr : p.nameEn, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (p) {
                        if (p != null) setModalState(() => selectedProduct = p);
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${lang.isArabic ? "المتوفر في المصدر" : "Available in Source"}: ${fromStock.toInt()} ${selectedProduct.baseUnit.split(" - ")[0]}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: fromStock < transferQty ? AppColors.expenseRed : Colors.green.shade800,
                            ),
                          ),
                          Text(
                            '${lang.isArabic ? "الحالي في الوجهة" : "Current in Target"}: ${toStock.toInt()}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: transferQty.toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: lang.isArabic ? 'الكمية المحولة *' : 'Transfer Quantity *',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (val) {
                        transferQty = double.tryParse(val) ?? 10.0;
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        labelText: lang.isArabic ? 'ملاحظات سند التحويل' : 'Transfer Notes',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: fromWarehouseId == toWarehouseId || fromStock < transferQty
                            ? null
                            : () {
                                db.transferStockBetweenWarehouses(
                                  fromWarehouseId: fromWarehouseId,
                                  toWarehouseId: toWarehouseId,
                                  items: [
                                    StockTransferItem(
                                      productId: selectedProduct.id,
                                      productName: selectedProduct.nameAr,
                                      quantity: transferQty,
                                      unit: selectedProduct.baseUnit.split(" - ")[0],
                                    ),
                                  ],
                                  requestedByUserId: auth.currentUser.id,
                                  requestedByUserName: auth.currentUser.name,
                                  notes: notesCtrl.text.trim(),
                                );
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(lang.isArabic ? 'تم تنفيذ سند النقل المخزني بنجاح!' : 'Stock transferred successfully!'),
                                    backgroundColor: AppColors.saleGreen,
                                  ),
                                );
                              },
                        icon: const Icon(Icons.check),
                        label: Text(lang.isArabic ? 'تأكيد أمر التحويل' : 'Confirm Stock Transfer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  // ---------------------------------------------------------------------------
  // Modal: Evening Van Return (تفريغ واسترجاع بضاعة السيارة لمستودع المركز)
  // ---------------------------------------------------------------------------
  void _showEveningVanReturnDialog(
    BuildContext context,
    WarehouseModel van,
    List<ProductModel> loadedItems,
    AppLanguage lang,
    DatabaseService db,
    AuthService auth,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(lang.isArabic ? 'تفريغ واسترجاع مخزون السيارة المسائي' : 'Evening Van Stock Reconciliation'),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.isArabic
                        ? 'سيتم استرجاع جميع الأصناف المتبقية في ${van.nameAr} وإعادتها إلى المستودع الرئيسي (WH-MAIN) لإغلاق جرد اليوم:'
                        : 'All remaining items in ${van.nameEn} will be returned to Main Warehouse (WH-MAIN):',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ...loadedItems.map((p) {
                    final qty = p.stockByWarehouse[van.id] ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: Text(lang.isArabic ? p.nameAr : p.nameEn, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                          Text('${qty.toInt()} ${p.baseUnit.split(" - ")[0]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final returnItems = loadedItems.map((p) {
                  final qty = p.stockByWarehouse[van.id] ?? 0.0;
                  return StockTransferItem(
                    productId: p.id,
                    productName: p.nameAr,
                    quantity: qty,
                    unit: p.baseUnit.split(" - ")[0],
                  );
                }).toList();

                db.transferStockBetweenWarehouses(
                  fromWarehouseId: van.id,
                  toWarehouseId: 'WH-MAIN',
                  items: returnItems,
                  requestedByUserId: auth.currentUser.id,
                  requestedByUserName: auth.currentUser.name,
                  notes: 'تفريغ نهاية اليوم - Evening Van Return & Reconciliation',
                );

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(lang.isArabic ? 'تم تفريغ واسترجاع بضاعة السيارة للمستودع الرئيسي بنجاح!' : 'Van stock returned to main warehouse!'),
                    backgroundColor: AppColors.saleGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(lang.isArabic ? 'تأكيد استرجاع المخزون' : 'Confirm Return'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Confirm Delete Product
  // ---------------------------------------------------------------------------
  void _confirmDeleteProduct(BuildContext context, ProductModel prod, AppLanguage lang, DatabaseService db) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(lang.isArabic ? 'حذف الصنف' : 'Delete Product'),
          content: Text(
            lang.isArabic
                ? 'هل أنت متأكد من رغبتك في حذف الصنف "${prod.nameAr}" من قائمة المخزون؟'
                : 'Are you sure you want to delete "${prod.nameEn}" from the catalog?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                db.deleteProduct(prod.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(lang.isArabic ? 'تم حذف الصنف' : 'Product deleted'),
                    backgroundColor: AppColors.expenseRed,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
              child: Text(lang.isArabic ? 'حذف' : 'Delete'),
            ),
          ],
        );
      },
    );
  }
}

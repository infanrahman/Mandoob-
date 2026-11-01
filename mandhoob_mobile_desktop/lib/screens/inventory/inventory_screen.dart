import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';
import '../../models/warehouse_model.dart';
import '../../models/stock_transfer_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedWarehouseFilter = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AppLanguage()]),
      builder: (context, _) {
        final db = DatabaseService();
        final lang = AppLanguage();

        return Scaffold(
          appBar: AppBar(
            title: Text(lang.isArabic ? 'إدارة المخزون وسيارات التوزيع' : 'Stock & Van Inventory'),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: lang.isArabic ? 'أرصدة الأصناف (Stock)' : 'Stock Levels'),
                Tab(text: lang.isArabic ? 'بضاعة السيارات (Vans)' : 'Van Inventory'),
                Tab(text: lang.isArabic ? 'سجل التحميل (Transfers)' : 'Transfer Log'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: All Products Stock
              _buildProductsStockTab(db, lang),
              // Tab 2: Van-specific Stock
              _buildVansStockTab(db, lang),
              // Tab 3: Stock Transfers Log
              _buildTransfersLogTab(db, lang),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showStockTransferDialog(context),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.move_to_inbox, color: Colors.white),
            label: Text(
              lang.isArabic ? 'تحميل بضاعة للسيارة' : 'Stock Transfer to Van',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsStockTab(DatabaseService db, AppLanguage lang) {
    final filtered = db.products.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = p.nameAr.toLowerCase().contains(q) ||
            p.nameEn.toLowerCase().contains(q) ||
            p.barcode.contains(q) ||
            p.sku.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: TextField(
            decoration: InputDecoration(
              hintText: lang.isArabic
                  ? 'البحث باسم الصنف، الباركود أو الرمز (SKU)...'
                  : 'Search by item name, barcode or SKU...',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = ''))
                  : null,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final prod = filtered[index];
              final totalStock = prod.getTotalStock();
              final mainStock = prod.getStockFor('WH-MAIN');
              final vanStock = prod.getStockFor('VAN-01');

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.isArabic ? prod.nameAr : prod.nameEn,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  '${lang.isArabic ? "الباركود" : "Barcode"}: ${prod.barcode} • ${lang.isArabic ? "الرمز" : "SKU"}: ${prod.sku}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: totalStock > prod.minStockAlert ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${lang.isArabic ? "الإجمالي" : "Total"}: ${totalStock.toInt()} ${prod.baseUnit}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: totalStock > prod.minStockAlert ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${lang.isArabic ? "المستودع الرئيسي" : "Main Warehouse"}: ${mainStock.toInt()}', overflow: TextOverflow.ellipsis),
                                Text('${lang.isArabic ? "سيارة 1 (محمد)" : "Van 1 (Mohammed)"}: ${vanStock.toInt()}', overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${lang.isArabic ? "التجزئة" : "Retail"}: ${prod.retailPrice.toStringAsFixed(2)} ${lang.isArabic ? "ر.س" : "SAR"}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              Text(
                                '${lang.isArabic ? "الجملة" : "Wholesale"}: ${prod.wholesalePrice.toStringAsFixed(2)} ${lang.isArabic ? "ر.س" : "SAR"}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (prod.batchNumber != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${lang.isArabic ? "التشغيلة" : "Batch"}: ${prod.batchNumber} • ${lang.isArabic ? "الانتهاء" : "Expiry"}: ${prod.expiryDate.toString().substring(0, 10)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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

  Widget _buildVansStockTab(DatabaseService db, AppLanguage lang) {
    final vans = db.warehouses.where((w) => w.isVan).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final van = vans[index];
        final vanTotalValue = db.getVanStockValue(van.id);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFEFF6FF),
                            child: Icon(Icons.directions_car, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.isArabic ? van.nameAr : van.nameEn,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${lang.isArabic ? "السائق" : "Driver"}: ${van.assignedDriverName ?? (lang.isArabic ? "غير معين" : "Unassigned")} | ${lang.isArabic ? "اللوحة" : "Plate"}: ${van.vehiclePlateNumber ?? "-"}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${vanTotalValue.toStringAsFixed(2)} ${lang.isArabic ? "ر.س" : "SAR"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.saleGreen),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  lang.isArabic ? 'الأصناف المحملة في السيارة حالياً:' : 'Items Currently Loaded in Van:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ...db.products.map((p) {
                  final qty = p.stockByWarehouse[van.id] ?? 0.0;
                  if (qty <= 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lang.isArabic ? p.nameAr : p.nameEn,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${qty.toInt()} ${p.baseUnit}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransfersLogTab(DatabaseService db, AppLanguage lang) {
    if (db.stockTransfers.isEmpty) {
      return Center(
        child: Text(
          lang.isArabic ? 'لا توجد عمليات نقل بضاعة حتى الآن' : 'No stock transfer records yet',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: db.stockTransfers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final trf = db.stockTransfers[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFDCFCE7),
              child: Icon(Icons.move_to_inbox, color: Colors.green),
            ),
            title: Text('${trf.transferNumber} • ${trf.toVanName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${trf.date.toLocal().toString().substring(0, 16)} • ${lang.isArabic ? "بواسطة" : "By"}: ${trf.requestedByUserName}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Chip(
              label: Text(
                lang.isArabic ? 'تم التحميل' : 'Loaded',
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          ),
        );
      },
    );
  }

  void _showStockTransferDialog(BuildContext context) {
    final db = DatabaseService();
    final auth = AuthService();
    final vans = db.warehouses.where((w) => w.isVan).toList();
    if (vans.isEmpty) return;

    String selectedVanId = vans.first.id;
    ProductModel selectedProd = db.products.first;
    double qty = 10.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final mainWhStock = selectedProd.stockByWarehouse['WH-MAIN'] ?? 0.0;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تحميل بضاعة من المستودع الرئيسي إلى السيارة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedVanId,
                    decoration: const InputDecoration(labelText: 'اختر سيارة التوزيع (Target Van)'),
                    items: vans.map((v) => DropdownMenuItem(value: v.id, child: Text(v.nameAr, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedVanId = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ProductModel>(
                    isExpanded: true,
                    value: selectedProd,
                    decoration: const InputDecoration(labelText: 'اختر الصنف المراد نقله'),
                    items: db.products.map((p) => DropdownMenuItem(value: p, child: Text(p.nameAr, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (p) {
                      if (p != null) setModalState(() => selectedProd = p);
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'الرصيد المتوفر في المستودع الرئيسي: ${mainWhStock.toInt()} ${selectedProd.baseUnit}',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: '10',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'الكمية المحمولة'),
                    onChanged: (val) {
                      qty = double.tryParse(val) ?? 10.0;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        db.transferStockToVan(
                          fromWarehouseId: 'WH-MAIN',
                          toVanId: selectedVanId,
                          items: [
                            StockTransferItem(
                              productId: selectedProd.id,
                              productName: selectedProd.nameAr,
                              quantity: qty,
                              unit: selectedProd.baseUnit,
                            ),
                          ],
                          requestedByUserId: auth.currentUser.id,
                          requestedByUserName: auth.currentUser.name,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تسجيل سند التحميل وتحديث مخزون السيارة بنجاح!'),
                            backgroundColor: AppColors.saleGreen,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('تأكيد تحميل البضاعة'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

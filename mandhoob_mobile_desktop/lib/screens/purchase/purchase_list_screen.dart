import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/stock_transfer_model.dart';
import '../../models/supplier_model.dart';
import '../../models/product_model.dart';
import '../../models/expense_model.dart';
import '../../widgets/date_filter_bar.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  String _billSearchQuery = '';
  DateFilterPreset _billDatePreset = DateFilterPreset.all;
  DateTimeRange? _billCustomRange;
  String _paymentFilter = 'all'; // 'all', 'credit', 'cash'

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AppLanguage(), AuthService()]),
      builder: (context, _) {
        final db = DatabaseService();
        final auth = AuthService();
        final lang = AppLanguage();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';

        // Inward Purchase Bills from expenses/ledger with Date + Search filtering
        final purchaseBills = db.expenses
            .where((e) => e.expenseNumber.startsWith('PUR'))
            .where((e) => DateFilterHelper.matches(e.date, _billDatePreset, _billCustomRange))
            .where((e) {
              if (_paymentFilter == 'credit' && !e.paymentMode.toLowerCase().contains('credit') && !e.paymentMode.contains('آجل')) return false;
              if (_paymentFilter == 'cash' && (e.paymentMode.toLowerCase().contains('credit') || e.paymentMode.contains('آجل'))) return false;

              if (_billSearchQuery.isNotEmpty) {
                final q = _billSearchQuery.toLowerCase().trim();
                return e.expenseNumber.toLowerCase().contains(q) ||
                    e.description.toLowerCase().contains(q) ||
                    e.spentByUserName.toLowerCase().contains(q) ||
                    e.paymentMode.toLowerCase().contains(q);
              }
              return true;
            })
            .toList();

        final totalPurchaseAmount = purchaseBills.fold(0.0, (sum, b) => sum + b.totalWithVat);
        final totalVatAmount = purchaseBills.fold(0.0, (sum, b) => sum + b.vatAmount);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // 1. KPI Purchases Overview Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.isArabic ? 'إجمالي المشتريات المعروضة' : 'Total Purchases Filtered',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${totalPurchaseAmount.toStringAsFixed(2)} $curr',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lang.isArabic
                                ? 'ضريبة المشتريات المستردة: ${totalVatAmount.toStringAsFixed(2)} $curr'
                                : 'Input VAT (Recoverable): ${totalVatAmount.toStringAsFixed(2)} $curr',
                            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 24),
                          const SizedBox(height: 2),
                          Text(
                            '${purchaseBills.length}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            lang.isArabic ? 'فاتورة شراء' : 'Bills',
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Search & Text Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: lang.isArabic
                        ? 'ابحث برقم الفاتورة، اسم المورد أو طريقة الدفع...'
                        : 'Search bill #, supplier or payment mode...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.purchaseBlue),
                    suffixIcon: _billSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _billSearchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.purchaseBlue, width: 1.5),
                    ),
                  ),
                  onChanged: (val) => setState(() => _billSearchQuery = val),
                ),
              ),

              // 3. Date Filter Bar
              DateFilterBar(
                selectedPreset: _billDatePreset,
                customRange: _billCustomRange,
                onPresetChanged: (preset) => setState(() => _billDatePreset = preset),
                onCustomRangeChanged: (range) => setState(() => _billCustomRange = range),
              ),

              // 4. Payment Mode Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    _buildPaymentChip(
                      label: lang.isArabic ? 'الكل' : 'All',
                      isSelected: _paymentFilter == 'all',
                      onTap: () => setState(() => _paymentFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _buildPaymentChip(
                      label: lang.isArabic ? 'آجل (على الحساب)' : 'Credit (Payable)',
                      isSelected: _paymentFilter == 'credit',
                      color: Colors.orange.shade800,
                      onTap: () => setState(() => _paymentFilter = 'credit'),
                    ),
                    const SizedBox(width: 8),
                    _buildPaymentChip(
                      label: lang.isArabic ? 'نقداً / بنك' : 'Cash / Bank',
                      isSelected: _paymentFilter == 'cash',
                      color: AppColors.saleGreen,
                      onTap: () => setState(() => _paymentFilter = 'cash'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 5. Purchase Bills List
              Expanded(
                child: purchaseBills.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              lang.isArabic ? 'لا توجد فواتير شراء مطابقة' : 'No purchase bills match your filters',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 14, right: 14, bottom: 90),
                        itemCount: purchaseBills.length,
                        itemBuilder: (context, index) {
                          final bill = purchaseBills[index];
                          final isCredit = bill.paymentMode.toLowerCase().contains('credit') ||
                              bill.paymentMode.contains('آجل');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppColors.purchaseBlue.withOpacity(0.12),
                                        child: const Icon(Icons.inventory_rounded, color: AppColors.purchaseBlue, size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              bill.expenseNumber,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              bill.description,
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Total Amount with VAT
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${bill.totalWithVat.toStringAsFixed(2)} $curr',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.purchaseBlue,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isCredit ? Colors.orange.shade50 : Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: isCredit ? Colors.orange.shade200 : Colors.green.shade200,
                                              ),
                                            ),
                                            child: Text(
                                              isCredit ? (lang.isArabic ? 'آجل' : 'Credit') : (lang.isArabic ? 'نقدي' : 'Cash'),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isCredit ? Colors.orange.shade800 : Colors.green.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 18, thickness: 0.8, color: AppColors.cardBorder),
                                  // Details info row
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        bill.date.toString().substring(0, 10),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(width: 14),
                                      const Icon(Icons.warehouse_outlined, size: 12, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        lang.isArabic ? 'المستودع الرئيسي' : 'Main Warehouse',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'VAT (15%): ${bill.vatAmount.toStringAsFixed(2)} $curr',
                                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: auth.can((p) => p.canCreatePurchase)
              ? FloatingActionButton.extended(
                  onPressed: () => _showCreatePurchaseBillDialog(context, db, auth, lang),
                  backgroundColor: AppColors.purchaseBlue,
                  elevation: 4,
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 20),
                  label: Text(
                    lang.isArabic ? 'فاتورة شراء جديدة' : '+ New Purchase Bill',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildPaymentChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? AppColors.purchaseBlue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialog: Record Inward Purchase Bill & Update Inventory
  // ---------------------------------------------------------------------------
  void _showCreatePurchaseBillDialog(
    BuildContext context,
    DatabaseService db,
    AuthService auth,
    AppLanguage lang,
  ) {
    if (db.suppliers.isEmpty || db.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.isArabic
                ? 'يرجى تسجيل مورد وأصناف أولاً قبل إنشاء فاتورة شراء'
                : 'Please register suppliers and products first',
          ),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    String selectedSupplierId = db.suppliers.first.id;
    String selectedWarehouseId = 'WH-MAIN';
    String selectedProductId = db.products.first.id;
    final qtyController = TextEditingController(text: '50');
    final unitCostController = TextEditingController(
      text: db.products.first.wholesalePrice.toStringAsFixed(2),
    );
    String paymentMode = 'Credit - آجل';
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final curr = lang.isArabic ? 'ر.س' : 'SAR';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final qty = double.tryParse(qtyController.text) ?? 0.0;
            final cost = double.tryParse(unitCostController.text) ?? 0.0;
            final subtotal = qty * cost;
            final vat = subtotal * 0.15;
            final total = subtotal + vat;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                    const SizedBox(height: 14),
                    Text(
                      lang.isArabic ? 'تسجيل فاتورة شراء واردة وتوريد المخزون' : 'Record Inward Purchase Bill',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),

                    // Supplier selector
                    DropdownButtonFormField<String>(
                      value: selectedSupplierId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: lang.isArabic ? 'المورد المعتمد *' : 'Supplier *'),
                      items: db.suppliers.map((s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text(lang.isArabic ? s.nameAr : s.nameEn, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedSupplierId = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Warehouse selector
                    DropdownButtonFormField<String>(
                      value: selectedWarehouseId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: lang.isArabic ? 'المستودع المستلم *' : 'Receiving Warehouse *'),
                      items: [
                        DropdownMenuItem(
                          value: 'WH-MAIN',
                          child: Text(lang.isArabic ? 'المستودع المركزي - الرياض' : 'Central Warehouse - Riyadh'),
                        ),
                        DropdownMenuItem(
                          value: 'WH-DEPOT',
                          child: Text(lang.isArabic ? 'مستودع جدة الإقليمي' : 'Jeddah Regional Depot'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedWarehouseId = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Product selector
                    DropdownButtonFormField<String>(
                      value: selectedProductId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: lang.isArabic ? 'الصنف المورد *' : 'Purchased Product *'),
                      items: db.products.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text('${lang.isArabic ? p.nameAr : p.nameEn} (حالي: ${p.getTotalStock().toStringAsFixed(0)})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedProductId = val;
                            final p = db.products.firstWhere((item) => item.id == val);
                            unitCostController.text = p.wholesalePrice.toStringAsFixed(2);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Quantity and Cost
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: lang.isArabic ? 'الكمية الموردة *' : 'Quantity *'),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: unitCostController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: lang.isArabic ? 'سعر الشراء الفردي *' : 'Unit Cost *'),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Payment mode
                    DropdownButtonFormField<String>(
                      value: paymentMode,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: lang.isArabic ? 'طريقة السداد' : 'Payment Mode'),
                      items: const [
                        DropdownMenuItem(value: 'Credit - آجل', child: Text('Credit - آجل (ذمم دائنة)')),
                        DropdownMenuItem(value: 'Cash - نقداً', child: Text('Cash - نقداً (الخزينة)')),
                        DropdownMenuItem(value: 'Bank Transfer - تحويل بنكي', child: Text('Bank Transfer - تحويل بنكي')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => paymentMode = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(labelText: lang.isArabic ? 'ملاحظات ورقم بوليصة الشحن' : 'Notes / Waybill Ref'),
                    ),
                    const SizedBox(height: 14),

                    // Bill Summary Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(lang.isArabic ? 'المجموع قبل الضريبة:' : 'Subtotal:'),
                              Text('${subtotal.toStringAsFixed(2)} $curr'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(lang.isArabic ? 'ضريبة القيمة المضافة (15%):' : 'VAT (15%):'),
                              Text('${vat.toStringAsFixed(2)} $curr', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.isArabic ? 'إجمالي الفاتورة النهائي:' : 'Grand Total:',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '${total.toStringAsFixed(2)} $curr',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.purchaseBlue),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purchaseBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          if (qty <= 0 || cost <= 0) return;

                          final supp = db.suppliers.firstWhere((s) => s.id == selectedSupplierId);
                          final prod = db.products.firstWhere((p) => p.id == selectedProductId);

                          db.recordPurchaseBill(
                            supplierId: selectedSupplierId,
                            warehouseId: selectedWarehouseId,
                            items: [
                              StockTransferItem(
                                productId: prod.id,
                                productName: prod.nameAr,
                                quantity: qty,
                                unit: prod.baseUnit,
                              ),
                            ],
                            subtotal: subtotal,
                            vatAmount: vat,
                            paymentMode: paymentMode,
                            createdByUserId: auth.currentUser.id,
                            createdByUserName: auth.currentUser.name,
                            notes: notesController.text.trim(),
                          );

                          Navigator.pop(ctx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang.isArabic
                                    ? 'تم تسجيل فاتورة الشراء وتوريد الكمية ($qty) إلى المخزون بنجاح!'
                                    : 'Purchase bill recorded and stock increased by ($qty) successfully!',
                              ),
                              backgroundColor: AppColors.saleGreen,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text(
                          lang.isArabic ? 'اعتماد فاتورة الشراء وتوريد البضاعة' : 'Confirm Purchase & Stock In',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

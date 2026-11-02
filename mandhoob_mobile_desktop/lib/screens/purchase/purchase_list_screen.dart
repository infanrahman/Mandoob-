import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/supplier_model.dart';
import '../../models/product_model.dart';
import '../../models/stock_transfer_model.dart';
import '../../models/expense_model.dart';
import '../suppliers/supplier_detail_screen.dart';
import '../suppliers/payment_out_dialog.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        final auth = AuthService();
        final lang = AppLanguage();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';

        // Filter suppliers
        final filteredSuppliers = db.suppliers.where((s) {
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return s.nameAr.toLowerCase().contains(q) ||
                s.nameEn.toLowerCase().contains(q) ||
                s.phone.contains(q) ||
                (s.vatNumber?.contains(q) ?? false);
          }
          return true;
        }).toList();

        // Inward Purchase Bills from expenses / ledger
        final purchaseBills = db.expenses
            .where((e) => e.expenseNumber.startsWith('PUR'))
            .toList();

        final totalPurchaseAmount = purchaseBills.fold(0.0, (sum, b) => sum + b.totalWithVat);

        return Scaffold(
          appBar: AppBar(
            title: Text(lang.isArabic ? 'المشتريات والموردين' : 'Purchases & Suppliers'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1),
                tooltip: lang.isArabic ? 'إضافة مورد جديد' : 'Add New Supplier',
                onPressed: () => _showAddSupplierDialog(context, db, lang),
              ),
              IconButton(
                icon: const Icon(Icons.post_add),
                tooltip: lang.isArabic ? 'تسجيل فاتورة شراء واردة' : 'Record Purchase Bill',
                onPressed: () => _showCreatePurchaseBillDialog(context, db, auth, lang),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  icon: const Icon(Icons.business, size: 20),
                  text: lang.isArabic ? 'الموردين والائتمان' : 'Suppliers & Payables',
                ),
                Tab(
                  icon: const Icon(Icons.receipt_long, size: 20),
                  text: lang.isArabic ? 'فواتير المشتريات (${purchaseBills.length})' : 'Purchase Bills (${purchaseBills.length})',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // -----------------------------------------------------------------
              // Tab 1: Suppliers & Credit
              // -----------------------------------------------------------------
              Column(
                children: [
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: Colors.white,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: lang.isArabic
                            ? 'ابحث باسم المورد أو رقم الهاتف أو الرقم الضريبي...'
                            : 'Search supplier, phone or VAT #...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: AppColors.purchaseBlue, size: 22),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _searchQuery = ''))
                            : null,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),

                  // Payables Summary Banner
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.account_balance_wallet, color: AppColors.purchaseBlue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lang.isArabic ? "إجمالي المستحقات للموردين:" : "Total Payables to Suppliers:",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${db.totalPayables.toStringAsFixed(2)} $curr',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.purchaseBlue),
                        ),
                      ],
                    ),
                  ),

                  // Suppliers List
                  Expanded(
                    child: filteredSuppliers.isEmpty
                        ? Center(
                            child: Text(lang.isArabic ? 'لا يوجد موردون مطابقون للبحث' : 'No suppliers found'),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(left: 14, right: 14, top: 4, bottom: 96),
                            itemCount: filteredSuppliers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final supp = filteredSuppliers[index];
                              final suppName = lang.isArabic ? supp.nameAr : supp.nameEn;
                              final hasPayable = supp.currentBalance > 0;

                              return Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => SupplierDetailScreen(supplier: supp)),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: AppColors.purchaseBlue.withOpacity(0.12),
                                              child: const Icon(Icons.business, color: AppColors.purchaseBlue, size: 20),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(suppName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${supp.phone} • ${supp.city ?? ""}',
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                  ),
                                                  if (supp.vatNumber != null)
                                                    Text(
                                                      '${lang.isArabic ? "الرقم الضريبي" : "VAT"}: ${supp.vatNumber}',
                                                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${supp.currentBalance.toStringAsFixed(2)} $curr',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: hasPayable ? AppColors.purchaseBlue : Colors.green,
                                                  ),
                                                ),
                                                Text(
                                                  hasPayable ? (lang.isArabic ? 'مستحق له' : 'Payable') : (lang.isArabic ? 'مسدد' : 'Settled'),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: hasPayable ? AppColors.purchaseBlue : Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${lang.isArabic ? "سقف الائتمان" : "Limit"}: ${supp.creditLimit.toStringAsFixed(0)} $curr',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                            Row(
                                              children: [
                                                OutlinedButton.icon(
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (_) => PaymentOutDialog(supplier: supp),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.payment, size: 14),
                                                  label: Text(lang.isArabic ? 'سند صرف' : 'Pay Out', style: const TextStyle(fontSize: 11)),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Icon(Icons.chevron_right, size: 16, color: AppColors.purchaseBlue),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),

              // -----------------------------------------------------------------
              // Tab 2: Purchase Invoices / Bills
              // -----------------------------------------------------------------
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang.isArabic ? 'إجمالي المشتريات الواردة:' : 'Total Inward Purchases:',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${totalPurchaseAmount.toStringAsFixed(2)} $curr',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: purchaseBills.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    lang.isArabic
                                        ? 'لا توجد فواتير مشتريات مسجلة بعد'
                                        : 'No purchase bills recorded yet',
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _showCreatePurchaseBillDialog(context, db, auth, lang),
                                    icon: const Icon(Icons.add),
                                    label: Text(lang.isArabic ? '+ تسجيل أول فاتورة مشتريات' : '+ Record First Purchase Bill'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(left: 14, right: 14, top: 4, bottom: 96),
                            itemCount: purchaseBills.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final bill = purchaseBills[index];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade50,
                                    child: const Icon(Icons.receipt, color: AppColors.purchaseBlue),
                                  ),
                                  title: Text(bill.expenseNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    '${bill.description}\n${bill.date.toString().substring(0, 16)} • ${bill.paymentMode}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${bill.totalWithVat.toStringAsFixed(2)} $curr',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purchaseBlue, fontSize: 13),
                                      ),
                                      Text(
                                        'VAT: ${bill.vatAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreatePurchaseBillDialog(context, db, auth, lang),
            backgroundColor: AppColors.purchaseBlue,
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
            label: Text(
              lang.isArabic ? '+ فاتورة شراء واردة' : '+ Inward Purchase Bill',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Dialog: Add New Supplier
  // ---------------------------------------------------------------------------
  void _showAddSupplierDialog(BuildContext context, DatabaseService db, AppLanguage lang) {
    final nameArController = TextEditingController();
    final nameEnController = TextEditingController();
    final phoneController = TextEditingController();
    final vatController = TextEditingController();
    final crController = TextEditingController();
    final creditLimitController = TextEditingController(text: '50000');
    final graceDaysController = TextEditingController(text: '45');
    final cityController = TextEditingController(text: 'الرياض - Riyadh');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.isArabic ? 'إضافة مورد معتمد جديد' : 'Add New Supplier',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameArController,
                  decoration: InputDecoration(
                    labelText: lang.isArabic ? 'اسم المورد / الشركة بالعربي *' : 'Supplier Name (Arabic) *',
                    prefixIcon: const Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameEnController,
                  decoration: InputDecoration(
                    labelText: lang.isArabic ? 'اسم المورد بالإنجليزي' : 'Supplier Name (English)',
                    prefixIcon: const Icon(Icons.language),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: lang.isArabic ? 'رقم الهاتف / الجوال *' : 'Phone Number *',
                          prefixIcon: const Icon(Icons.phone),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: vatController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: lang.isArabic ? 'الرقم الضريبي (15 رقم)' : 'VAT # (15 digits)',
                          prefixIcon: const Icon(Icons.verified),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: creditLimitController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: lang.isArabic ? 'سقف الائتمان (ر.س)' : 'Credit Limit (SAR)',
                          prefixIcon: const Icon(Icons.credit_card),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: graceDaysController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: lang.isArabic ? 'مهلة السداد (يوم)' : 'Terms (Days)',
                          prefixIcon: const Icon(Icons.timer_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cityController,
                  decoration: InputDecoration(
                    labelText: lang.isArabic ? 'المدينة' : 'City',
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.purchaseBlue),
                    onPressed: () {
                      final nameAr = nameArController.text.trim();
                      final phone = phoneController.text.trim();
                      if (nameAr.isEmpty || phone.isEmpty) return;

                      final newSupp = SupplierModel(
                        id: 'SUPP-${DateTime.now().millisecondsSinceEpoch}',
                        nameAr: nameAr,
                        nameEn: nameEnController.text.trim().isEmpty ? nameAr : nameEnController.text.trim(),
                        phone: phone,
                        vatNumber: vatController.text.trim().isEmpty ? null : vatController.text.trim(),
                        crNumber: crController.text.trim().isEmpty ? null : crController.text.trim(),
                        creditLimit: double.tryParse(creditLimitController.text.trim()) ?? 50000.0,
                        creditPeriodDays: int.tryParse(graceDaysController.text.trim()) ?? 45,
                        city: cityController.text.trim(),
                      );

                      db.addSupplier(newSupp);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(lang.isArabic ? 'تمت إضافة المورد بنجاح!' : 'Supplier added successfully!'),
                          backgroundColor: AppColors.saleGreen,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: Text(
                      lang.isArabic ? 'حفظ المورد' : 'Save Supplier',
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
          content: Text(lang.isArabic ? 'يرجى تسجيل مورد وأصناف أولاً' : 'Please register suppliers and products first'),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final qty = double.tryParse(qtyController.text) ?? 0.0;
            final cost = double.tryParse(unitCostController.text) ?? 0.0;
            final subtotal = qty * cost;
            final vat = subtotal * 0.15;
            final total = subtotal + vat;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.isArabic ? 'تسجيل فاتورة شراء واردة وزيادة المخزون' : 'Record Inward Purchase Bill',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),

                    // Supplier selector
                    DropdownButtonFormField<String>(
                      value: selectedSupplierId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: lang.isArabic ? 'المورد المعتمد' : 'Supplier'),
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
                      decoration: InputDecoration(labelText: lang.isArabic ? 'مستودع الاستلام' : 'Receiving Warehouse'),
                      items: db.warehouses.map((w) {
                        return DropdownMenuItem(
                          value: w.id,
                          child: Text(w.nameAr, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedWarehouseId = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Product selector
                    DropdownButtonFormField<String>(
                      value: selectedProductId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: lang.isArabic ? 'الصنف المستلم' : 'Product'),
                      items: db.products.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.nameAr} (${p.sku})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedProductId = val;
                            final prod = db.products.firstWhere((p) => p.id == val);
                            unitCostController.text = prod.wholesalePrice.toStringAsFixed(2);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: lang.isArabic ? 'الكمية المستلمة' : 'Quantity',
                              prefixIcon: const Icon(Icons.numbers),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: unitCostController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: lang.isArabic ? 'سعر التكلفة (ر.س)' : 'Unit Cost (SAR)',
                              prefixIcon: const Icon(Icons.attach_money),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: paymentMode,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: lang.isArabic ? 'طريقة السداد' : 'Payment Terms'),
                      items: const [
                        DropdownMenuItem(value: 'Credit - آجل', child: Text('آجل (زيادة رصيد المورد الدائن)')),
                        DropdownMenuItem(value: 'Cash - نقداً', child: Text('نقداً (من صندوق المشتريات)')),
                        DropdownMenuItem(value: 'Bank - تحويل بنكي', child: Text('تحويل بنكي رسمي')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => paymentMode = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: lang.isArabic ? 'ملاحظات / رقم بوليصة الشحن' : 'Notes / B/L #',
                        prefixIcon: const Icon(Icons.note),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Calculations preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(lang.isArabic ? 'المبلغ قبل الضريبة:' : 'Subtotal:'),
                              Text('${subtotal.toStringAsFixed(2)} SAR'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(lang.isArabic ? 'ضريبة المدخلات (15%):' : 'Input VAT (15%):'),
                              Text('${vat.toStringAsFixed(2)} SAR'),
                            ],
                          ),
                          const Divider(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.isArabic ? 'الإجمالي الشامل:' : 'Grand Total:',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${total.toStringAsFixed(2)} SAR',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purchaseBlue),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.purchaseBlue),
                        onPressed: () {
                          if (qty <= 0 || cost <= 0) return;

                          final prod = db.products.firstWhere((p) => p.id == selectedProductId);
                          final item = StockTransferItem(
                            productId: prod.id,
                            productName: prod.nameAr,
                            quantity: qty,
                            unit: prod.baseUnit,
                          );

                          db.recordPurchaseBill(
                            supplierId: selectedSupplierId,
                            warehouseId: selectedWarehouseId,
                            items: [item],
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
                                    ? 'تم تسجيل فاتورة الشراء وزيادة رصيد المستودع بنجاح!'
                                    : 'Purchase bill recorded and stock increased successfully!',
                              ),
                              backgroundColor: AppColors.saleGreen,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text(
                          lang.isArabic ? 'اعتماد فاتورة الشراء وإدخال المخزون' : 'Approve Bill & Receive Stock',
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

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/supplier_model.dart';
import 'supplier_detail_screen.dart';
import 'payment_out_dialog.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  String _searchQuery = '';
  String _balanceFilter = 'all'; // 'all', 'due', 'settled'

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AppLanguage(), AuthService()]),
      builder: (context, _) {
        final db = DatabaseService();
        final auth = AuthService();
        final lang = AppLanguage();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';

        // Filter suppliers based on query and balance status
        final filteredSuppliers = db.suppliers.where((s) {
          if (_balanceFilter == 'due' && s.currentBalance <= 0) return false;
          if (_balanceFilter == 'settled' && s.currentBalance > 0) return false;

          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase().trim();
            return s.nameAr.toLowerCase().contains(q) ||
                s.nameEn.toLowerCase().contains(q) ||
                s.phone.contains(q) ||
                (s.vatNumber?.contains(q) ?? false) ||
                (s.crNumber?.contains(q) ?? false) ||
                (s.city?.toLowerCase().contains(q) ?? false);
          }
          return true;
        }).toList();

        final totalPayables = db.suppliers.fold(0.0, (sum, s) => sum + (s.currentBalance > 0 ? s.currentBalance : 0.0));
        final suppliersWithDue = db.suppliers.where((s) => s.currentBalance > 0).length;

        return Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddSupplierDialog(context, db, lang),
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
            label: Text(
              lang.isArabic ? 'إضافة مورد جديد' : '+ New Supplier',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            backgroundColor: AppColors.purchaseBlue,
            elevation: 4,
          ),
          body: Column(
            children: [
              // 1. KPI Payables Overview
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.2),
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
                            lang.isArabic ? 'إجمالي المستحقات للموردين' : 'Total Supplier Payables',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${totalPayables.toStringAsFixed(2)} $curr',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lang.isArabic
                                ? '$suppliersWithDue موردين مستحق لهم مبالغ آجلة'
                                : '$suppliersWithDue suppliers with due balances',
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
                          const Icon(Icons.business_rounded, color: Colors.white, size: 24),
                          const SizedBox(height: 2),
                          Text(
                            '${db.suppliers.length}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            lang.isArabic ? 'مورد مسجل' : 'Suppliers',
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Search & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: lang.isArabic
                        ? 'بحث بالاسم، الجوال، الرقم الضريبي، السجل أو المدينة...'
                        : 'Search by name, phone, VAT, CR, or city...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.purchaseBlue),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
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
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              // 3. Quick Filter Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: lang.isArabic ? 'الكل (${db.suppliers.length})' : 'All (${db.suppliers.length})',
                        isSelected: _balanceFilter == 'all',
                        onTap: () => setState(() => _balanceFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: lang.isArabic ? 'مستحق له دفعات ($suppliersWithDue)' : 'Has Due Balance ($suppliersWithDue)',
                        isSelected: _balanceFilter == 'due',
                        color: Colors.red.shade700,
                        onTap: () => setState(() => _balanceFilter = 'due'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: lang.isArabic ? 'رصيد مسوّى صفر' : 'Settled (Zero)',
                        isSelected: _balanceFilter == 'settled',
                        color: AppColors.saleGreen,
                        onTap: () => setState(() => _balanceFilter = 'settled'),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Supplier List
              Expanded(
                child: filteredSuppliers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              lang.isArabic ? 'لا توجد نتائج مطابقة' : 'No matching suppliers found',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 14, right: 14, bottom: 90),
                        itemCount: filteredSuppliers.length,
                        itemBuilder: (context, index) {
                          final supplier = filteredSuppliers[index];
                          final hasDue = supplier.currentBalance > 0;

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
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SupplierDetailScreen(supplier: supplier),
                                  ),
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
                                          radius: 20,
                                          backgroundColor: AppColors.purchaseBlue.withOpacity(0.12),
                                          child: const Icon(Icons.business, color: AppColors.purchaseBlue, size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                lang.isArabic ? supplier.nameAr : supplier.nameEn,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${supplier.phone} • ${supplier.city ?? (lang.isArabic ? "الرياض" : "Riyadh")}',
                                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Due Balance Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: hasDue ? Colors.red.shade50 : Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: hasDue ? Colors.red.shade200 : Colors.green.shade200,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                hasDue ? (lang.isArabic ? 'مستحق عليه' : 'Payable') : (lang.isArabic ? 'مسوّى' : 'Settled'),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: hasDue ? Colors.red.shade800 : Colors.green.shade800,
                                                ),
                                              ),
                                              Text(
                                                '${supplier.currentBalance.toStringAsFixed(2)} $curr',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: hasDue ? Colors.red.shade900 : Colors.green.shade900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 18, thickness: 0.8, color: AppColors.cardBorder),
                                    // Tax / CR info row
                                    Row(
                                      children: [
                                        if (supplier.vatNumber != null) ...[
                                          const Icon(Icons.confirmation_number_outlined, size: 13, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'VAT: ${supplier.vatNumber}',
                                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                          ),
                                        ],
                                        const Spacer(),
                                        // Action buttons
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => PaymentOutDialog(
                                                supplier: supplier,
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.payments_outlined, size: 13),
                                          label: Text(lang.isArabic ? 'سند صرف' : 'Pay Out'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red.shade700,
                                            side: BorderSide(color: Colors.red.shade300),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            visualDensity: VisualDensity.compact,
                                            textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => SupplierDetailScreen(supplier: supplier),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.receipt_long, size: 13),
                                          label: Text(lang.isArabic ? 'كشف الحساب' : 'Statement'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            visualDensity: VisualDensity.compact,
                                            textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
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
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
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

  void _showAddSupplierDialog(BuildContext context, DatabaseService db, AppLanguage lang) {
    final nameArCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final vatCtrl = TextEditingController();
    final crCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: lang.isArabic ? 'الرياض' : 'Riyadh');
    final balanceCtrl = TextEditingController(text: '0.00');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 14,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.purchaseBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.business_rounded, color: AppColors.purchaseBlue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    lang.isArabic ? 'إضافة مورد معتمد جديد' : 'Add New Supplier',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameArCtrl,
                decoration: InputDecoration(
                  labelText: lang.isArabic ? 'اسم المورد (بالعربية) *' : 'Supplier Name (Arabic) *',
                  prefixIcon: const Icon(Icons.business_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameEnCtrl,
                decoration: InputDecoration(
                  labelText: lang.isArabic ? 'اسم المورد (بالإنجليزية)' : 'Supplier Name (English)',
                  prefixIcon: const Icon(Icons.translate, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: lang.isArabic ? 'رقم الهاتف *' : 'Phone *',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: cityCtrl,
                      decoration: InputDecoration(
                        labelText: lang.isArabic ? 'المدينة' : 'City',
                        prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: vatCtrl,
                keyboardType: TextInputType.number,
                maxLength: 15,
                decoration: InputDecoration(
                  labelText: lang.isArabic ? 'الرقم الضريبي (15 رقم)' : 'VAT Number (15 digits)',
                  prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: crCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: lang.isArabic ? 'السجل التجاري' : 'CR Number',
                        prefixIcon: const Icon(Icons.receipt_long_outlined, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: balanceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: lang.isArabic ? 'الرصيد الافتتاحي (ر.س)' : 'Opening Due (SAR)',
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(lang.isArabic ? 'إلغاء' : 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purchaseBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (nameArCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang.isArabic ? 'يرجى إدخال اسم المورد ورقم الهاتف' : 'Please provide supplier name and phone',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final newSupplier = SupplierModel(
                          id: 'SUP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                          nameAr: nameArCtrl.text.trim(),
                          nameEn: nameEnCtrl.text.trim().isNotEmpty ? nameEnCtrl.text.trim() : nameArCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          vatNumber: vatCtrl.text.trim().isNotEmpty ? vatCtrl.text.trim() : null,
                          crNumber: crCtrl.text.trim().isNotEmpty ? crCtrl.text.trim() : null,
                          city: cityCtrl.text.trim(),
                          openingBalance: double.tryParse(balanceCtrl.text.trim()) ?? 0.0,
                          currentBalance: double.tryParse(balanceCtrl.text.trim()) ?? 0.0,
                        );

                        db.addSupplier(newSupplier);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              lang.isArabic ? 'تمت إضافة المورد بنجاح' : 'Supplier added successfully',
                            ),
                            backgroundColor: AppColors.saleGreen,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(
                        lang.isArabic ? 'حفظ المورد' : 'Save Supplier',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

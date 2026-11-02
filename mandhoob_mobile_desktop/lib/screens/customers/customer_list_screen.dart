import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/database_service.dart';
import '../../models/customer_model.dart';
import '../../models/invoice_model.dart';
import '../sales/create_invoice_screen.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

enum CustomerFilterType {
  all,
  hasBalance,
  overLimit,
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String _searchQuery = '';
  CustomerFilterType _selectedStatusFilter = CustomerFilterType.all;
  String? _selectedAreaFilter;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AppLanguage()]),
      builder: (context, _) {
        final db = DatabaseService();
        final lang = AppLanguage();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';

        // Extract unique areas
        final areas = db.customers
            .map((c) => c.routeArea ?? c.district ?? '')
            .where((a) => a.isNotEmpty)
            .toSet()
            .toList();

        final filteredCustomers = db.customers.where((c) {
          // 1. Status Filter
          if (_selectedStatusFilter == CustomerFilterType.hasBalance && c.currentBalance <= 0) {
            return false;
          }
          if (_selectedStatusFilter == CustomerFilterType.overLimit && c.currentBalance <= c.creditLimit) {
            return false;
          }
          // 2. Area Filter
          if (_selectedAreaFilter != null) {
            final a = c.routeArea ?? c.district ?? '';
            if (a != _selectedAreaFilter) return false;
          }
          // 3. Search query
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase().trim();
            final matchesName = c.nameAr.toLowerCase().contains(q) || c.nameEn.toLowerCase().contains(q);
            final matchesPhone = c.phone.contains(q);
            final matchesVat = c.vatNumber?.contains(q) ?? false;
            final matchesCr = c.crNumber?.contains(q) ?? false;
            final matchesArea = (c.routeArea?.toLowerCase().contains(q) ?? false) ||
                (c.district?.toLowerCase().contains(q) ?? false) ||
                (c.city?.toLowerCase().contains(q) ?? false);
            return matchesName || matchesPhone || matchesVat || matchesCr || matchesArea;
          }
          return true;
        }).toList();

        final hasFilter = _searchQuery.isNotEmpty ||
            _selectedStatusFilter != CustomerFilterType.all ||
            _selectedAreaFilter != null;

        return Scaffold(
          body: Column(
            children: [
              // Search & Filter Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: lang.isArabic
                            ? 'ابحث باسم العميل أو الجوال أو الرقم الضريبي أو الحي...'
                            : 'Search customer, phone, VAT #, or area...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 22),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        isDense: true,
                        fillColor: Colors.grey.shade100,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: 8),
                    // Quick Status Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: lang.isArabic ? 'كافة العملاء' : 'All Customers',
                            count: db.customers.length,
                            isSelected: _selectedStatusFilter == CustomerFilterType.all && _selectedAreaFilter == null,
                            onTap: () => setState(() {
                              _selectedStatusFilter = CustomerFilterType.all;
                              _selectedAreaFilter = null;
                            }),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            label: lang.isArabic ? 'عليهم مديونية' : 'Has Balance',
                            count: db.customers.where((c) => c.currentBalance > 0).length,
                            isSelected: _selectedStatusFilter == CustomerFilterType.hasBalance,
                            onTap: () => setState(() => _selectedStatusFilter = _selectedStatusFilter == CustomerFilterType.hasBalance ? CustomerFilterType.all : CustomerFilterType.hasBalance),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            label: lang.isArabic ? 'تجاوز الائتمان' : 'Over Limit',
                            count: db.customers.where((c) => c.currentBalance > c.creditLimit).length,
                            isSelected: _selectedStatusFilter == CustomerFilterType.overLimit,
                            color: Colors.red,
                            onTap: () => setState(() => _selectedStatusFilter = _selectedStatusFilter == CustomerFilterType.overLimit ? CustomerFilterType.all : CustomerFilterType.overLimit),
                          ),
                          if (areas.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            ...areas.map((area) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _buildFilterChip(
                                  label: area,
                                  isSelected: _selectedAreaFilter == area,
                                  color: Colors.teal,
                                  onTap: () => setState(() => _selectedAreaFilter = _selectedAreaFilter == area ? null : area),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (hasFilter)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  color: Colors.grey.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${lang.isArabic ? "نتائج البحث" : "Results"}: ${filteredCustomers.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      InkWell(
                        onTap: () => setState(() {
                          _searchQuery = '';
                          _selectedStatusFilter = CustomerFilterType.all;
                          _selectedAreaFilter = null;
                        }),
                        child: Text(
                          lang.isArabic ? 'إلغاء التصفية' : 'Clear Filters',
                          style: const TextStyle(fontSize: 11, color: AppColors.expenseRed, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),

              // Total Receivables Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance, color: AppColors.accent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lang.isArabic ? "مستحقات السوق:" : "Total Receivables:",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${db.totalReceivables.toStringAsFixed(2)} $curr',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange),
                    ),
                  ],
                ),
              ),

              // Customer List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(left: 14, right: 14, top: 4, bottom: 96),
                  itemCount: filteredCustomers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final cust = filteredCustomers[index];
                    final displayName = lang.isArabic ? cust.nameAr : cust.nameEn;
                    final hasDebt = cust.currentBalance > 0;

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 1,
                      shadowColor: Colors.black.withOpacity(0.05),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailScreen(customer: cust),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    child: Text(
                                      displayName.isNotEmpty ? displayName.substring(0, 1) : 'C',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                displayName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (cust.isVatRegistered) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  lang.isArabic ? 'ضريبي' : 'Tax',
                                                  style: const TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${cust.phone} • ${cust.routeArea}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Due Balance Badge
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${cust.currentBalance.toStringAsFixed(2)} $curr',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: hasDebt ? AppColors.expenseRed : Colors.green,
                                        ),
                                      ),
                                      Text(
                                        hasDebt
                                            ? (lang.isArabic ? 'مستحق' : 'Due')
                                            : (lang.isArabic ? 'خالص' : 'Settled'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: hasDebt ? AppColors.expenseRed : Colors.green,
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
                                    '${lang.isArabic ? "سقف الائتمان" : "Limit"}: ${cust.creditLimit.toStringAsFixed(0)} $curr',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.add_shopping_cart, size: 18, color: AppColors.saleGreen),
                                        tooltip: lang.isArabic ? 'إصدار فاتورة للعميل' : 'New Invoice',
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CreateInvoiceScreen(
                                                defaultType: cust.isVatRegistered
                                                    ? InvoiceType.taxInvoice
                                                    : InvoiceType.simplifiedTaxInvoice,
                                                preselectedCustomer: cust,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                                        tooltip: lang.isArabic ? 'تعديل البيانات' : 'Edit Customer',
                                        onPressed: () => _showAddOrEditCustomerDialog(context, cust, db, lang),
                                      ),
                                      Text(
                                        lang.isArabic ? 'كشف الحساب' : 'Statement',
                                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
                                      const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddOrEditCustomerDialog(context, null, db, lang),
            backgroundColor: AppColors.primary,
            elevation: 4,
            icon: const Icon(Icons.person_add, color: Colors.white, size: 18),
            label: Text(
              lang.isArabic ? 'إضافة عميل' : '+ Add Customer',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        );
      },
    );
  }

  void _showAddOrEditCustomerDialog(
    BuildContext context,
    CustomerModel? existingCustomer,
    DatabaseService db,
    AppLanguage lang,
  ) {
    final isEdit = existingCustomer != null;
    final nameArController = TextEditingController(text: existingCustomer?.nameAr ?? '');
    final nameEnController = TextEditingController(text: existingCustomer?.nameEn ?? '');
    final phoneController = TextEditingController(text: existingCustomer?.phone ?? '');
    final vatController = TextEditingController(text: existingCustomer?.vatNumber ?? '');
    final crController = TextEditingController(text: existingCustomer?.crNumber ?? '');
    final creditLimitController = TextEditingController(
      text: existingCustomer != null ? existingCustomer.creditLimit.toStringAsFixed(0) : '0',
    );
    final gracePeriodController = TextEditingController(
      text: existingCustomer != null ? existingCustomer.creditPeriodDays.toString() : '0',
    );
    final routeAreaController = TextEditingController(
      text: existingCustomer?.routeArea ?? '',
    );
    final streetController = TextEditingController(text: existingCustomer?.street ?? '');
    final districtController = TextEditingController(text: existingCustomer?.district ?? '');
    final cityController = TextEditingController(text: existingCustomer?.city ?? (db.city.isNotEmpty ? db.city : ''));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit
                              ? (lang.isArabic ? 'تعديل بيانات العميل والائتمان' : 'Edit Customer & Credit Limit')
                              : (lang.isArabic ? 'تسجيل عميل جديد في النظام' : 'Register New Customer'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (isEdit)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed),
                            tooltip: lang.isArabic ? 'حذف العميل' : 'Delete Customer',
                            onPressed: () {
                              Navigator.pop(ctx);
                              _confirmDeleteCustomer(context, existingCustomer, db, lang);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: nameArController,
                      decoration: InputDecoration(
                        labelText: lang.isArabic ? 'اسم العميل / المؤسسة بالعربي *' : 'Customer Name (Arabic) *',
                        prefixIcon: const Icon(Icons.store),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: nameEnController,
                      decoration: InputDecoration(
                        labelText: lang.isArabic ? 'اسم العميل بالإنجليزي' : 'Customer Name (English)',
                        prefixIcon: const Icon(Icons.business_outlined),
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
                              labelText: lang.isArabic ? 'رقم الجوال *' : 'Phone Number *',
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
                              prefixIcon: const Icon(Icons.credit_score),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: gracePeriodController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: lang.isArabic ? 'مهلة السداد (يوم)' : 'Grace Period (Days)',
                              prefixIcon: const Icon(Icons.timer_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: routeAreaController,
                      decoration: InputDecoration(
                        labelText: lang.isArabic ? 'مسار سيارة التوزيع / المنطقة' : 'Route / Delivery Area',
                        prefixIcon: const Icon(Icons.alt_route),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: districtController,
                            decoration: InputDecoration(
                              labelText: lang.isArabic ? 'الحي' : 'District',
                              prefixIcon: const Icon(Icons.location_on_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: cityController,
                            decoration: InputDecoration(
                              labelText: lang.isArabic ? 'المدينة' : 'City',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final nameAr = nameArController.text.trim();
                          final phone = phoneController.text.trim();
                          if (nameAr.isEmpty || phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(lang.isArabic ? 'يرجى إدخال اسم العميل ورقم الجوال' : 'Please fill required fields'),
                                backgroundColor: AppColors.expenseRed,
                              ),
                            );
                            return;
                          }

                          final creditLimit = double.tryParse(creditLimitController.text.trim()) ?? 10000.0;
                          final graceDays = int.tryParse(gracePeriodController.text.trim()) ?? 30;

                          if (isEdit) {
                            final updated = CustomerModel(
                              id: existingCustomer.id,
                              nameAr: nameAr,
                              nameEn: nameEnController.text.trim().isEmpty ? nameAr : nameEnController.text.trim(),
                              phone: phone,
                              email: existingCustomer.email,
                              vatNumber: vatController.text.trim().isEmpty ? null : vatController.text.trim(),
                              crNumber: crController.text.trim().isEmpty ? null : crController.text.trim(),
                              street: streetController.text.trim().isEmpty ? existingCustomer.street : streetController.text.trim(),
                              district: districtController.text.trim().isEmpty ? existingCustomer.district : districtController.text.trim(),
                              city: cityController.text.trim().isEmpty ? existingCustomer.city : cityController.text.trim(),
                              postalCode: existingCustomer.postalCode,
                              routeArea: routeAreaController.text.trim(),
                              creditLimit: creditLimit,
                              creditPeriodDays: graceDays,
                              openingBalance: existingCustomer.openingBalance,
                              currentBalance: existingCustomer.currentBalance,
                            );
                            db.updateCustomer(updated);
                          } else {
                            final newCust = CustomerModel(
                              id: 'CUST-${DateTime.now().millisecondsSinceEpoch}',
                              nameAr: nameAr,
                              nameEn: nameEnController.text.trim().isEmpty ? nameAr : nameEnController.text.trim(),
                              phone: phone,
                              vatNumber: vatController.text.trim().isEmpty ? null : vatController.text.trim(),
                              crNumber: crController.text.trim().isEmpty ? null : crController.text.trim(),
                              street: streetController.text.trim().isEmpty ? 'طريق الملك فهد' : streetController.text.trim(),
                              district: districtController.text.trim().isEmpty ? 'العليا' : districtController.text.trim(),
                              city: cityController.text.trim().isEmpty ? 'الرياض' : cityController.text.trim(),
                              routeArea: routeAreaController.text.trim(),
                              creditLimit: creditLimit,
                              creditPeriodDays: graceDays,
                              openingBalance: 0.0,
                              currentBalance: 0.0,
                            );
                            db.addCustomer(newCust);
                          }

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEdit
                                    ? (lang.isArabic ? 'تم تحديث بيانات العميل بنجاح!' : 'Customer updated successfully!')
                                    : (lang.isArabic ? 'تم تسجيل العميل وحفظه محلياً بنجاح!' : 'Customer added & persisted successfully!'),
                              ),
                              backgroundColor: AppColors.saleGreen,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: Text(
                          isEdit
                              ? (lang.isArabic ? 'حفظ التعديلات' : 'Save Changes')
                              : (lang.isArabic ? 'تأكيد وإضافة العميل' : 'Add Customer'),
                        ),
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

  void _confirmDeleteCustomer(BuildContext context, CustomerModel customer, DatabaseService db, AppLanguage lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.isArabic ? 'حذف العميل' : 'Delete Customer'),
        content: Text(
          lang.isArabic
              ? 'هل تريد بالتأكيد حذف العميل "${customer.nameAr}"؟'
              : 'Are you sure you want to delete "${customer.nameEn}"?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.isArabic ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            onPressed: () {
              db.deleteCustomer(customer.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(lang.isArabic ? 'تم حذف العميل بنجاح' : 'Customer deleted'),
                  backgroundColor: AppColors.expenseRed,
                ),
              );
            },
            child: Text(lang.isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    int? count,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final activeColor = color ?? AppColors.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.25) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

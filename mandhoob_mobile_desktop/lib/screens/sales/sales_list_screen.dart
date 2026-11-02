import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/invoice_model.dart';
import '../../widgets/date_filter_bar.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  String _searchQuery = '';
  InvoiceType? _selectedTypeFilter;
  PaymentStatus? _selectedPaymentFilter;
  DateFilterPreset _selectedDatePreset = DateFilterPreset.all;
  DateTimeRange? _customDateRange;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AppLanguage(), AuthService()]),
      builder: (context, _) {
        final db = DatabaseService();
        final lang = AppLanguage();
        final auth = AuthService();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';

        // Filter list with Date + Search + Type + Payment filters
        final filteredInvoices = db.invoices.where((inv) {
          // 1. Date filter
          if (!DateFilterHelper.matches(inv.invoiceDate, _selectedDatePreset, _customDateRange)) {
            return false;
          }
          // 2. Type filter
          if (_selectedTypeFilter != null && inv.type != _selectedTypeFilter) {
            return false;
          }
          // 3. Payment status filter
          if (_selectedPaymentFilter != null && inv.paymentStatus != _selectedPaymentFilter) {
            return false;
          }
          // 4. Advanced search query (invoice #, customer, VAT, salesman, notes)
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase().trim();
            final matchesNumber = inv.invoiceNumber.toLowerCase().contains(query);
            final matchesCustomer = inv.customerNameAr.toLowerCase().contains(query) ||
                inv.customerNameEn.toLowerCase().contains(query);
            final matchesVat = inv.customerVatNumber?.contains(query) ?? false;
            final matchesSalesman = inv.salesmanName.toLowerCase().contains(query);
            final matchesNotes = inv.notes?.toLowerCase().contains(query) ?? false;
            return matchesNumber || matchesCustomer || matchesVat || matchesSalesman || matchesNotes;
          }
          return true;
        }).toList();

        final filteredTotal = filteredInvoices.fold(0.0, (sum, i) => sum + (i.type == InvoiceType.salesReturn ? -i.grandTotal : i.grandTotal));
        final hasActiveFilter = _searchQuery.isNotEmpty ||
            _selectedTypeFilter != null ||
            _selectedPaymentFilter != null ||
            _selectedDatePreset != DateFilterPreset.all;

        return Scaffold(
          body: Column(
            children: [
              // Modern Mobile Search & Filter Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: lang.isArabic
                            ? 'ابحث برقم الفاتورة أو اسم العميل...'
                            : 'Search invoice # or customer...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 22),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        fillColor: Colors.grey.shade100,
                        filled: true,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: 8),
                    // Scrollable Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: lang.isArabic ? 'الكل' : 'All',
                            count: db.invoices.length,
                            isSelected: _selectedTypeFilter == null,
                            onTap: () => setState(() => _selectedTypeFilter = null),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: lang.isArabic ? 'مبسطة (سيارة)' : 'Simplified (Van)',
                            isSelected: _selectedTypeFilter == InvoiceType.simplifiedTaxInvoice,
                            onTap: () => setState(
                              () => _selectedTypeFilter = _selectedTypeFilter == InvoiceType.simplifiedTaxInvoice
                                  ? null
                                  : InvoiceType.simplifiedTaxInvoice,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: lang.isArabic ? 'ضريبية B2B' : 'B2B Tax',
                            isSelected: _selectedTypeFilter == InvoiceType.taxInvoice,
                            onTap: () => setState(
                              () => _selectedTypeFilter = _selectedTypeFilter == InvoiceType.taxInvoice
                                  ? null
                                  : InvoiceType.taxInvoice,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: lang.isArabic ? 'مرتجع' : 'Return',
                            isSelected: _selectedTypeFilter == InvoiceType.salesReturn,
                            onTap: () => setState(
                              () => _selectedTypeFilter = _selectedTypeFilter == InvoiceType.salesReturn
                                  ? null
                                  : InvoiceType.salesReturn,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Date Filter Bar
                    DateFilterBar(
                      selectedPreset: _selectedDatePreset,
                      customRange: _customDateRange,
                      onPresetChanged: (preset) => setState(() => _selectedDatePreset = preset),
                      onCustomRangeChanged: (range) => setState(() => _customDateRange = range),
                    ),
                  ],
                ),
              ),

              // Filter Summary / Reset Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                color: Colors.grey.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${lang.isArabic ? "النتائج" : "Results"}: ${filteredInvoices.length} (${filteredTotal.toStringAsFixed(2)} $curr)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    if (hasActiveFilter)
                      InkWell(
                        onTap: () => setState(() {
                          _searchQuery = '';
                          _selectedTypeFilter = null;
                          _selectedPaymentFilter = null;
                          _selectedDatePreset = DateFilterPreset.all;
                          _customDateRange = null;
                        }),
                        child: Row(
                          children: [
                            const Icon(Icons.refresh, size: 13, color: AppColors.expenseRed),
                            const SizedBox(width: 3),
                            Text(
                              lang.isArabic ? 'إعادة ضبط' : 'Reset Filters',
                              style: const TextStyle(fontSize: 11, color: AppColors.expenseRed, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),

              // Invoices List with Mobile Padding
              Expanded(
                child: filteredInvoices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              lang.isArabic
                                  ? 'لا توجد فواتير مطابقة للبحث'
                                  : 'No invoices found matching search',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 96),
                        itemCount: filteredInvoices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final inv = filteredInvoices[index];
                          final isReturn = inv.type == InvoiceType.salesReturn;
                          final isCredit = inv.paymentMethod == PaymentMethod.credit;
                          final custName = lang.isArabic ? inv.customerNameAr : inv.customerNameEn;

                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            elevation: 1,
                            shadowColor: Colors.black.withOpacity(0.06),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => InvoiceDetailScreen(invoice: inv),
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
                                    // Row 1: Invoice Number + Badge + Price
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: isReturn
                                                  ? AppColors.expenseRed.withOpacity(0.12)
                                                  : AppColors.saleGreen.withOpacity(0.12),
                                              child: Icon(
                                                isReturn ? Icons.assignment_return : Icons.receipt,
                                                size: 15,
                                                color: isReturn ? AppColors.expenseRed : AppColors.saleGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              inv.invoiceNumber,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Payment Status Pill
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isCredit ? AppColors.badgePartialBg : AppColors.badgePaidBg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isCredit
                                                    ? (lang.isArabic ? 'آجل' : 'Credit')
                                                    : (lang.isArabic ? 'نقداً' : 'Cash'),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isCredit
                                                      ? AppColors.badgePartialText
                                                      : AppColors.badgePaidText,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Grand Total
                                        Text(
                                          '${inv.grandTotal.toStringAsFixed(2)} $curr',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isReturn ? AppColors.expenseRed : AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // Row 2: Customer Name
                                    Row(
                                      children: [
                                        const Icon(Icons.storefront, size: 15, color: AppColors.textMuted),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            custName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    // Row 3: Van Info + Date + VAT
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                          children: [
                                            const Icon(Icons.directions_car, size: 13, color: AppColors.textMuted),
                                            const SizedBox(width: 4),
                                            Text(
                                              inv.warehouseName.split('-').first.trim(),
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                            const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                                            Text(
                                              inv.invoiceDate.toLocal().toString().substring(5, 16),
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'VAT: ${inv.totalVat.toStringAsFixed(2)} $curr',
                                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
          floatingActionButton: auth.can((p) => p.canCreateSale)
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
                    );
                  },
                  backgroundColor: AppColors.saleGreen,
                  elevation: 4,
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  label: Text(
                    lang.isArabic ? 'فاتورة جديدة' : '+ New Invoice',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? count,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.25) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

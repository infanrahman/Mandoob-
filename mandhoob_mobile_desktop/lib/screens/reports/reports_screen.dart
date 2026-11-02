import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/database_service.dart';
import '../../models/invoice_model.dart';
import '../../widgets/date_filter_bar.dart';
import '../customers/customer_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateFilterPreset _reportDatePreset = DateFilterPreset.thisMonth;
  DateTimeRange? _reportCustomRange;
  String _dayBookSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AppLanguage()]),
      builder: (context, _) {
        final db = DatabaseService();
        final lang = AppLanguage();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';

        // Filter invoices & expenses for the selected reporting period
        final periodInvoices = db.invoices
            .where((i) => DateFilterHelper.matches(i.invoiceDate, _reportDatePreset, _reportCustomRange))
            .toList();
        final periodExpenses = db.expenses
            .where((e) => DateFilterHelper.matches(e.date, _reportDatePreset, _reportCustomRange))
            .toList();

        // Calculate ZATCA Tax Return Numbers for Period
        final taxableSales = periodInvoices
            .where((i) => i.type != InvoiceType.salesReturn && i.type != InvoiceType.quotation)
            .fold(0.0, (sum, i) => sum + i.subtotal);
        final salesVat = periodInvoices
            .where((i) => i.type != InvoiceType.salesReturn && i.type != InvoiceType.quotation)
            .fold(0.0, (sum, i) => sum + i.totalVat);

        final salesReturns = periodInvoices
            .where((i) => i.type == InvoiceType.salesReturn)
            .fold(0.0, (sum, i) => sum + i.subtotal);
        final returnsVat = periodInvoices
            .where((i) => i.type == InvoiceType.salesReturn)
            .fold(0.0, (sum, i) => sum + i.totalVat);

        final netTaxableSales = taxableSales - salesReturns;
        final netOutputVat = salesVat - returnsVat;

        final expenseAmount = periodExpenses.fold(0.0, (sum, e) => sum + e.amount);
        final inputVat = periodExpenses.fold(0.0, (sum, e) => sum + e.vatAmount);

        final netVatPayableToZatca = netOutputVat - inputVat;
        final portfolioAging = db.getPortfolioReceivablesAging();

        return Scaffold(
          appBar: AppBar(
            title: Text(lang.isArabic ? 'التقارير والإقرار الضريبي والائتمان' : 'Reports & Tax Returns'),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              isScrollable: true,
              tabs: [
                Tab(text: lang.isArabic ? 'الإقرار الضريبي (ZATCA)' : 'ZATCA Tax Return'),
                Tab(text: lang.isArabic ? 'تقرير الائتمان وأعمار الديون (Aging)' : 'Aging Analysis'),
                Tab(text: lang.isArabic ? 'دفتر اليومية (Day Book)' : 'Day Book'),
                Tab(text: lang.isArabic ? 'أداء المندوبين (Van Reps)' : 'Salesman Performance'),
              ],
            ),
          ),
          body: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: DateFilterBar(
                  selectedPreset: _reportDatePreset,
                  customRange: _reportCustomRange,
                  onPresetChanged: (preset) => setState(() => _reportDatePreset = preset),
                  onCustomRangeChanged: (range) => setState(() => _reportCustomRange = range),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
              // Tab 1: Official ZATCA VAT Return
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user, color: Colors.green, size: 30),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.isArabic
                                      ? 'نموذج الإقرار الضريبي الرسمي - هيئة الزكاة والضريبة والجمارك'
                                      : 'Official ZATCA VAT Return Declaration Form',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  '${lang.isArabic ? "الرقم الضريبي للمنشأة" : "Company VAT ID"}: ${db.vatNumber}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      lang.isArabic ? 'أولاً: المبيعات الخاضعة للضريبة (Output VAT)' : '1. Standard Rated Sales (Output VAT)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),

                    _buildZatcaRow(
                      lang.isArabic ? 'بند 1: المبيعات الخاضعة للنسبة الأساسية 15%' : 'Item 1: Standard Rated Sales (15%)',
                      netTaxableSales,
                      netOutputVat,
                      curr,
                    ),
                    _buildZatcaRow(
                      lang.isArabic ? 'بند 2: المبيعات للمواطنين (خدمات إعفاء)' : 'Item 2: Private Healthcare / Education Exempt',
                      0.0,
                      0.0,
                      curr,
                    ),
                    _buildZatcaRow(
                      lang.isArabic ? 'بند 3: المبيعات الخاضعة لنسبة الصفر %0' : 'Item 3: Zero-Rated Domestic Sales (0%)',
                      0.0,
                      0.0,
                      curr,
                    ),
                    _buildZatcaRow(
                      lang.isArabic ? 'بند 4: الصادرات خارج المملكة' : 'Item 4: Exports outside KSA',
                      0.0,
                      0.0,
                      curr,
                    ),
                    const Divider(height: 20),
                    _buildZatcaRow(
                      lang.isArabic ? 'بند 7: إجمالي المبيعات وضريبة المخرجات' : 'Item 7: Total Sales & Output VAT',
                      netTaxableSales,
                      netOutputVat,
                      curr,
                      isHighlight: true,
                    ),

                    const SizedBox(height: 20),

                    Text(
                      lang.isArabic ? 'ثانياً: المشتريات والمصروفات (Input VAT)' : '2. Purchases & Expenses (Input VAT)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),

                    _buildZatcaRow(
                      lang.isArabic ? 'بند 8: المشتريات والمصروفات الخاضعة لـ 15%' : 'Item 8: Standard Rated Purchases (15%)',
                      expenseAmount,
                      inputVat,
                      curr,
                    ),
                    _buildZatcaRow(
                      lang.isArabic ? 'بند 9: الاستيرادات الخاضعة للضريبة' : 'Item 9: Taxable Imports at Customs',
                      0.0,
                      0.0,
                      curr,
                    ),
                    const Divider(height: 20),
                    _buildZatcaRow(
                      lang.isArabic ? 'بند 13: إجمالي المشتريات وضريبة المدخلات' : 'Item 13: Total Purchases & Input VAT',
                      expenseAmount,
                      inputVat,
                      curr,
                      isHighlight: true,
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.isArabic
                                      ? 'بند 14: صافي الضريبة المستحقة'
                                      : 'Item 14: Net VAT Payable',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  lang.isArabic
                                      ? '(ضريبة المخرجات - ضريبة المدخلات)'
                                      : '(Output VAT - Input VAT)',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${netVatPayableToZatca.toStringAsFixed(2)} $curr',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab 2: Credit & Debt Aging Report
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Portfolio Aging Buckets Banner
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.isArabic
                                  ? 'إجمالي ديون السوق حسب فترة التأخير (Portfolio Aging):'
                                  : 'Market Receivables Aging Breakdown:',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildAgingBox(lang.isArabic ? '0-30 يوم (جارية)' : '0-30 Days (Current)', portfolioAging['0_30']!, Colors.green, curr)),
                                const SizedBox(width: 6),
                                Expanded(child: _buildAgingBox(lang.isArabic ? '31-60 يوم (قريبة)' : '31-60 Days', portfolioAging['31_60']!, Colors.amber.shade800, curr)),
                                const SizedBox(width: 6),
                                Expanded(child: _buildAgingBox(lang.isArabic ? '61-90 يوم (متأخرة)' : '61-90 Days', portfolioAging['61_90']!, Colors.deepOrange, curr)),
                                const SizedBox(width: 6),
                                Expanded(child: _buildAgingBox(lang.isArabic ? '+90 يوم (حرجة)' : '90+ Days (Critical)', portfolioAging['90_plus']!, Colors.red.shade900, curr)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      lang.isArabic
                          ? 'أعمار الديون وسقف الائتمان لكل عميل (Customer Credit Breakdown):'
                          : 'Customer Credit & Receivables Aging Breakdown:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                    ),
                    const SizedBox(height: 10),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: db.customers.where((c) => c.currentBalance > 0).length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final cust = db.customers.where((c) => c.currentBalance > 0).toList()[index];
                        final aging = db.getCustomerAging(cust.id);

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
                                      child: Text(
                                        lang.isArabic ? cust.nameAr : cust.nameEn,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${lang.isArabic ? "المستحق" : "Due"}: ${cust.currentBalance.toStringAsFixed(2)} $curr',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.expenseRed),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${lang.isArabic ? "سقف الائتمان" : "Limit"}: ${cust.creditLimit.toStringAsFixed(0)} $curr • ${lang.isArabic ? "المتبقي" : "Available"}: ${cust.availableCredit.toStringAsFixed(2)} $curr',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Divider(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text('0-30: ${aging['0_30']!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.green), overflow: TextOverflow.ellipsis)),
                                    Expanded(child: Text('31-60: ${aging['31_60']!.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: Colors.amber.shade800), overflow: TextOverflow.ellipsis)),
                                    Expanded(child: Text('61-90: ${aging['61_90']!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.deepOrange), overflow: TextOverflow.ellipsis)),
                                    Expanded(child: Text('90+: ${aging['90_plus']!.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    Text(
                      lang.isArabic
                          ? 'أرصدة الموردين المستحقة وسقف الائتمان (Supplier Payables):'
                          : 'Supplier Payables & Credit Terms:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.purchaseBlue),
                    ),
                    const SizedBox(height: 10),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: db.suppliers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final supp = db.suppliers[index];
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFEFF6FF),
                              child: Icon(Icons.business, color: AppColors.purchaseBlue),
                            ),
                            title: Text(lang.isArabic ? supp.nameAr : supp.nameEn, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${lang.isArabic ? "سقف الائتمان" : "Credit Limit"}: ${supp.creditLimit.toStringAsFixed(0)} $curr • ${lang.isArabic ? "مهلة" : "Terms"}: ${supp.creditPeriodDays} ${lang.isArabic ? "يوم" : "Days"}'),
                            trailing: Text(
                              '${supp.currentBalance.toStringAsFixed(2)} $curr',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purchaseBlue, fontSize: 14),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Tab 3: Day Book (Filtered by Period & Search)
              Builder(
                builder: (context) {
                  final dayBookInvoices = periodInvoices.where((inv) {
                    if (_dayBookSearchQuery.isNotEmpty) {
                      final q = _dayBookSearchQuery.toLowerCase().trim();
                      return inv.invoiceNumber.toLowerCase().contains(q) ||
                          inv.customerNameAr.toLowerCase().contains(q) ||
                          inv.customerNameEn.toLowerCase().contains(q);
                    }
                    return true;
                  }).toList();

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: lang.isArabic ? 'ابحث برقم القيد أو اسم العميل...' : 'Search day book...',
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primary),
                            suffixIcon: _dayBookSearchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () => setState(() => _dayBookSearchQuery = ''),
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            fillColor: Colors.grey.shade100,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) => setState(() => _dayBookSearchQuery = val),
                        ),
                      ),
                      Expanded(
                        child: dayBookInvoices.isEmpty
                            ? Center(
                                child: Text(
                                  lang.isArabic ? 'لا توجد قيود مسجلة لهذه الفترة' : 'No entries for this period',
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: dayBookInvoices.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final inv = dayBookInvoices[index];
                                  return Card(
                                    child: ListTile(
                                      leading: Icon(
                                        inv.type == InvoiceType.salesReturn ? Icons.assignment_return : Icons.receipt,
                                        color: inv.type == InvoiceType.salesReturn ? AppColors.expenseRed : AppColors.saleGreen,
                                      ),
                                      title: Text('${inv.invoiceNumber} • ${lang.isArabic ? inv.customerNameAr : inv.customerNameEn}'),
                                      subtitle: Text(inv.invoiceDate.toLocal().toString().substring(0, 16)),
                                      trailing: Text(
                                        '${inv.grandTotal.toStringAsFixed(2)} $curr',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),

              // Tab 4: Salesman Performance
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(child: Icon(Icons.person)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang.isArabic ? 'محمد الدوسري - سيارة 1' : 'Mohammed Al-Dossari - Van 1',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      lang.isArabic ? 'مسار: الرياض شمال • أداء ممتاز' : 'Route: Riyadh North • Excellent',
                                      style: const TextStyle(fontSize: 12, color: Colors.green),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(lang.isArabic ? 'المبيعات' : "Sales", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                                    Text(
                                      '${db.todaySalesTotal.toStringAsFixed(2)} $curr',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.saleGreen),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(lang.isArabic ? 'التحصيل' : 'Cash In', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                                    Text(
                                      '${db.cashInHandTotal.toStringAsFixed(2)} $curr',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(lang.isArabic ? 'بضاعة السيارة' : 'Van Stock', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                                    Text(
                                      '${db.getVanStockValue('VAN-01').toStringAsFixed(0)} $curr',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
},
    );
  }

  Widget _buildAgingBox(String title, double amount, Color color, String curr) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            amount > 0 ? '${amount.toStringAsFixed(0)} $curr' : '0',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildZatcaRow(String label, double amount, double vat, String curr, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: isHighlight ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${amount.toStringAsFixed(2)} $curr',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${vat.toStringAsFixed(2)} $curr',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isHighlight ? AppColors.primary : AppColors.saleGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

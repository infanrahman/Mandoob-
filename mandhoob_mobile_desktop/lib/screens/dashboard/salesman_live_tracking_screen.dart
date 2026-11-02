import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/van_salesman_progress_model.dart';
import '../../models/customer_model.dart';
import '../../models/invoice_model.dart';
import '../../models/product_model.dart';
import '../../models/stock_transfer_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../customers/payment_in_dialog.dart';
import '../sales/create_invoice_screen.dart';
import '../sales/invoice_detail_screen.dart';

class SalesmanLiveTrackingScreen extends StatefulWidget {
  final VanSalesmanProgressModel progress;

  const SalesmanLiveTrackingScreen({super.key, required this.progress});

  @override
  State<SalesmanLiveTrackingScreen> createState() => _SalesmanLiveTrackingScreenState();
}

class _SalesmanLiveTrackingScreenState extends State<SalesmanLiveTrackingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        final curr = lang.isArabic ? 'ر.س' : 'SAR';

        // Find live progress for this van from DatabaseService if available
        final liveProg = db.salesmenProgress.firstWhere(
          (p) => p.vanId == widget.progress.vanId,
          orElse: () => widget.progress,
        );
        final settlement = liveProg.settlement;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(liveProg.salesmanName, style: const TextStyle(fontSize: 16)),
                Text(
                  '${liveProg.vanName} (${liveProg.vehiclePlateNumber})',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1),
                tooltip: lang.isArabic ? 'إضافة عميل جديد للمسار' : 'Add Customer to Route',
                onPressed: () => _showAddCustomerDialog(context, liveProg.vanId, liveProg.assignedRouteName, lang),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              isScrollable: true,
              tabs: [
                Tab(text: lang.isArabic ? 'مسار العملاء والائتمان' : 'Route & Credit'),
                Tab(text: lang.isArabic ? 'سجل العمليات الميدانية' : 'Operations Feed'),
                Tab(text: lang.isArabic ? 'مخزون السيارة والتحميل' : 'Van Stock'),
                Tab(text: lang.isArabic ? 'تسوية الصندوق اليومية' : 'EOD Settlement'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Customer Visits Journey & Credit & Invoices
              _buildRouteStopsTab(liveProg, db, lang, curr),

              // Tab 2: Operations Audit & Activity Feed
              _buildOperationsFeedTab(liveProg, db, lang, curr),

              // Tab 3: Van Stock Breakdown & Morning/Evening load
              _buildVanStockTab(liveProg, db, lang, curr),

              // Tab 4: Evening Cash & Van Settlement
              _buildCashSettlementTab(liveProg, settlement, lang, curr),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddCustomerDialog(context, liveProg.vanId, liveProg.assignedRouteName, lang),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: Text(
              lang.isArabic ? 'إضافة عميل للمسار' : '+ Add Customer',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: Route Stops with Credit Limit, Pending Invoices & Collected Invoices
  // ---------------------------------------------------------------------------
  Widget _buildRouteStopsTab(VanSalesmanProgressModel prog, DatabaseService db, AppLanguage lang, String curr) {
    return ListView(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 96),
      children: [
        // Live Performance KPI Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF1E3A8A)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      prog.assignedRouteName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${prog.visitedStopsCount}/${prog.totalStopsCount} ${lang.isArabic ? "محطات" : "Stops"}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 20),
              // Targets Progress Bars
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${lang.isArabic ? "المبيعات" : "Sales"}: ${prog.actualSalesAchieved.toStringAsFixed(0)} / ${prog.dailySalesTarget.toStringAsFixed(0)} $curr',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: prog.salesTargetRatio,
                            minHeight: 6,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${lang.isArabic ? "التحصيل" : "Collections"}: ${prog.actualCollectionsAchieved.toStringAsFixed(0)} / ${prog.dailyCollectionTarget.toStringAsFixed(0)} $curr',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: prog.dailyCollectionTarget > 0 ? (prog.actualCollectionsAchieved / prog.dailyCollectionTarget).clamp(0.0, 1.0) : 0.0,
                            minHeight: 6,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Route Schedule Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                lang.isArabic ? 'جدول زيارات العملاء والائتمان الميداني' : 'Customer Route, Credit & Invoices',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddCustomerDialog(context, prog.vanId, prog.assignedRouteName, lang),
              icon: const Icon(Icons.add, size: 16),
              label: Text(lang.isArabic ? 'إضافة عميل' : '+ Add', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // List of Customer Stops with Credit & Pending/Collected Invoices
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: prog.routeStops.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final stop = prog.routeStops[index];
            final isVisited = stop.status == StopVisitStatus.visited;
            final isSkipped = stop.status == StopVisitStatus.skipped;

            // Fetch live pending and collected invoices for this customer
            final pendingInvoices = db.getPendingInvoicesForCustomer(stop.customerId);
            final collectedInvoices = db.getCollectedInvoicesForCustomer(stop.customerId);
            final vouchers = db.getPaymentVouchersForCustomer(stop.customerId);

            final customerMatch = db.customers.where((c) => c.id == stop.customerId);
            final liveCustomer = customerMatch.isNotEmpty
                ? customerMatch.first
                : CustomerModel(
                    id: stop.customerId,
                    nameAr: stop.customerNameAr,
                    nameEn: stop.customerNameAr,
                    phone: stop.phone,
                    district: stop.district,
                    creditLimit: stop.creditLimit,
                    currentBalance: stop.currentBalance,
                  );

            final availableCredit = liveCustomer.availableCredit;
            final currentDebt = liveCustomer.currentBalance;

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 1,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isVisited
                        ? Colors.green.shade300
                        : (isSkipped ? Colors.grey.shade300 : AppColors.cardBorder),
                    width: isVisited ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Sequence Badge + Customer Name + Visit Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: isVisited
                              ? Colors.green.shade100
                              : (isSkipped ? Colors.grey.shade200 : AppColors.primary.withValues(alpha: 0.12)),
                          child: Text(
                            '${stop.sequenceOrder}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isVisited
                                  ? Colors.green.shade800
                                  : (isSkipped ? Colors.black54 : AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.customerNameAr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 12, color: AppColors.textMuted),
                                  const SizedBox(width: 3),
                                  Text(
                                    stop.district,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                                  const Icon(Icons.phone, size: 12, color: AppColors.textMuted),
                                  const SizedBox(width: 3),
                                  Text(
                                    stop.phone,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isVisited
                                ? Colors.green.shade50
                                : (isSkipped ? Colors.grey.shade100 : Colors.blue.shade50),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isVisited
                                ? (lang.isArabic ? 'تمت الزيارة' : 'Visited')
                                : (isSkipped ? (lang.isArabic ? 'تم التخطي' : 'Skipped') : (lang.isArabic ? 'قيد الانتظار' : 'Pending')),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isVisited
                                  ? Colors.green.shade800
                                  : (isSkipped ? Colors.black54 : AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 18),

                    // Credit Limit & Financial Terms Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.isArabic ? 'سقف الائتمان' : 'Credit Limit',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${liveCustomer.creditLimit.toStringAsFixed(0)} $curr',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  lang.isArabic ? 'الرصيد المستحق' : 'Due Balance',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${currentDebt.toStringAsFixed(2)} $curr',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: currentDebt > 0 ? AppColors.expenseRed : Colors.green,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  lang.isArabic ? 'المتبقي للآجل' : 'Available',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${availableCredit.toStringAsFixed(2)} $curr',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: availableCredit < 1000 ? AppColors.expenseRed : Colors.green.shade800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Pending Invoices Section (فواتير معلقة غير مسددة)
                    if (pendingInvoices.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.expenseRed),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${lang.isArabic ? "فواتير آجلة معلقة" : "Pending Invoices"}: ${pendingInvoices.length} (${pendingInvoices.fold(0.0, (sum, i) => sum + i.remainingBalance).toStringAsFixed(2)} $curr)',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.expenseRed),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Collected Invoices / Receipts Section (فواتير وسندات تم تحصيلها)
                    if (collectedInvoices.isNotEmpty || vouchers.isNotEmpty || stop.collectedAmount != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${lang.isArabic ? "تم تحصيله اليوم" : "Collected Today"}: ${((stop.collectedAmount ?? 0.0) > 0 ? stop.collectedAmount! : vouchers.fold<double>(0.0, (s, v) => s + v.amount)).toStringAsFixed(2)} $curr',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Direct Salesman Action Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // New Invoice Button
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateInvoiceScreen(
                                  preselectedCustomer: liveCustomer,
                                  preselectedWarehouseId: prog.vanId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.receipt_long, size: 14),
                          label: Text(lang.isArabic ? 'إنشاء فاتورة' : '+ Invoice'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.saleGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),

                        // Collect Debt Payment Button
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => PaymentInDialog(customer: liveCustomer),
                            );
                          },
                          icon: const Icon(Icons.payments, size: 14),
                          label: Text(lang.isArabic ? 'سند تحصيل' : 'Collect'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),

                        // Toggle Visit Status Button
                        OutlinedButton.icon(
                          onPressed: () {
                            db.updateRouteStopStatus(
                              vanId: prog.vanId,
                              customerId: stop.customerId,
                              status: isVisited ? StopVisitStatus.pending : StopVisitStatus.visited,
                              collectedAmount: isVisited ? null : stop.collectedAmount,
                            );
                          },
                          icon: Icon(isVisited ? Icons.undo : Icons.check, size: 14),
                          label: Text(
                            isVisited
                                ? (lang.isArabic ? 'تراجع' : 'Undo')
                                : (lang.isArabic ? 'تمت الزيارة' : 'Mark Visited'),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: Live Operations & Audit Activity Feed
  // ---------------------------------------------------------------------------
  Widget _buildOperationsFeedTab(VanSalesmanProgressModel prog, DatabaseService db, AppLanguage lang, String curr) {
    final operations = db.getSalesmanOperationsLog(prog.vanId);

    if (operations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_toggle_off, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 10),
              Text(
                lang.isArabic ? 'لم يتم تسجيل عمليات لهذه السيارة بعد' : 'No operations recorded yet today for this van',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: operations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final op = operations[index];
        final type = op['type'] as String;
        final title = op['title'] as String;
        final subtitle = op['subtitle'] as String;
        final date = op['date'] as DateTime;
        final icon = op['icon'] as IconData;
        final color = op['color'] as Color;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(
              '$subtitle\n${date.toLocal().toString().substring(11, 16)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            trailing: type == 'invoice' && op['invoice'] != null
                ? IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: op['invoice'] as InvoiceModel)),
                      );
                    },
                  )
                : null,
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: Van Stock Breakdown & Valuation
  // ---------------------------------------------------------------------------
  Widget _buildVanStockTab(VanSalesmanProgressModel prog, DatabaseService db, AppLanguage lang, String curr) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Van Stock Valuation Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        lang.isArabic ? 'تقييم مخزون السيارة لليوم' : "Today's Van Stock Valuation",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showLoadVanStockModal(context, prog.vanId, db, lang),
                      icon: const Icon(Icons.add_shopping_cart, size: 14),
                      label: Text(lang.isArabic ? 'تحميل بضاعة' : 'Load Stock'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildStockValueCol(lang.isArabic ? 'رصيد الصباح' : 'Morning Load', '${prog.morningOpeningStockValue.toStringAsFixed(0)} $curr', Colors.blue)),
                    Expanded(child: _buildStockValueCol(lang.isArabic ? 'المبيعات' : 'Sold Today', '- ${prog.totalSalesStockValue.toStringAsFixed(0)} $curr', Colors.green)),
                    Expanded(child: _buildStockValueCol(lang.isArabic ? 'المتبقي بالمساء' : 'Evening Remaining', '${prog.remainingEveningStockValue.toStringAsFixed(0)} $curr', AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          lang.isArabic ? 'قائمة الأصناف المحملة بالسيارة (Loaded Items)' : 'Loaded Items on Van',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: db.products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final prod = db.products[index];
            final vanQty = prod.stockByWarehouse[prog.vanId] ?? 0.0;
            if (vanQty <= 0) return const SizedBox.shrink();

            return Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2, color: AppColors.secondary),
                title: Text(lang.isArabic ? prod.nameAr : prod.nameEn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('${lang.isArabic ? "باركود" : "Barcode"}: ${prod.barcode} • ${lang.isArabic ? "تجزئة" : "Retail"}: ${prod.retailPrice.toStringAsFixed(2)} $curr'),
                trailing: Text(
                  '${vanQty.toInt()} ${prod.baseUnit}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: Daily Van Settlement (EOD Cash Handover)
  // ---------------------------------------------------------------------------
  Widget _buildCashSettlementTab(VanSalesmanProgressModel prog, DailyVanSettlement set, AppLanguage lang, String curr) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.point_of_sale, color: Colors.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lang.isArabic
                        ? 'تسوية نهاية اليوم (EOD Handover): يتم مطابقة الكاش الفعلي مع مبيعات الفواتير وسندات القبض ومصروفات الوقود.'
                        : 'End of Day (EOD) Handover: Reconciles physical cash against cash invoices, receipts, and fuel expenses.',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSettlementRow(lang.isArabic ? 'عهدة نقد بداية اليوم (Float Cash)' : 'Morning Float Cash', '+ ${set.openingCashFloat.toStringAsFixed(2)} $curr'),
                  const SizedBox(height: 8),
                  _buildSettlementRow(lang.isArabic ? 'مبيعات نقدية (Cash Invoices)' : 'Cash Invoices Total', '+ ${set.totalCashSales.toStringAsFixed(2)} $curr', isPositive: true),
                  const SizedBox(height: 8),
                  _buildSettlementRow(lang.isArabic ? 'تحصيلات ديون سابقة (Payment In)' : 'Debt Collections (Payment In)', '+ ${set.totalCollections.toStringAsFixed(2)} $curr', isPositive: true),
                  const SizedBox(height: 8),
                  _buildSettlementRow(lang.isArabic ? 'مصروفات المحروقات والسيارة' : 'Van Running & Fuel Expenses', '- ${set.totalVanExpenses.toStringAsFixed(2)} $curr', isNegative: true),
                  const Divider(height: 24),
                  _buildSettlementRow(lang.isArabic ? 'مبيعات بطاقات / مدى (Mada)' : 'Mada / Card Sales', '${set.totalMadaSales.toStringAsFixed(2)} $curr (${lang.isArabic ? "حساب بنكي" : "Bank"})'),
                  const SizedBox(height: 8),
                  _buildSettlementRow(lang.isArabic ? 'مبيعات آجلة (Credit Sales)' : 'Credit Sales', '${set.totalCreditSales.toStringAsFixed(2)} $curr (${lang.isArabic ? "ذمم مدينة" : "Receivables"})'),
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lang.isArabic ? 'المبلغ الواجب تسليمه للخزينة:' : 'Net Cash Handover:',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${set.expectedCashHandover.toStringAsFixed(2)} $curr',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lang.isArabic
                          ? 'تم تأكيد استلام النقد وإقفال تسوية السيارة لليوم بنجاح!'
                          : 'Confirmed cash handover and closed van daily settlement successfully!',
                    ),
                    backgroundColor: AppColors.saleGreen,
                  ),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: Text(lang.isArabic ? 'تأكيد استلام النقد وإقفال اليومية' : 'Confirm Cash Handover & Close Day'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saleGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Quick Add Customer Dialog (Salesman on-the-road onboarding)
  // ---------------------------------------------------------------------------
  void _showAddCustomerDialog(BuildContext context, String vanId, String routeArea, AppLanguage lang) {
    final formKey = GlobalKey<FormState>();
    final nameArController = TextEditingController();
    final nameEnController = TextEditingController();
    final phoneController = TextEditingController();
    final districtController = TextEditingController(text: routeArea.contains('(') ? routeArea.split('(')[1].replaceAll(')', '').split('،').first.trim() : 'العليا');
    final creditLimitController = TextEditingController(text: '15000');
    final creditDaysController = TextEditingController(text: '30');
    final vatController = TextEditingController();

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
            child: Form(
              key: formKey,
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
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.person_add, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.isArabic ? 'إضافة عميل جديد لمسار السيارة' : 'Add New Customer to Van Route',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              lang.isArabic ? 'تسجيل تموينات / سوبرماركت أثناء الجولة الميدانية' : 'Register market/grocery during field route',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Trade Name (Arabic)
                  TextFormField(
                    controller: nameArController,
                    decoration: InputDecoration(
                      labelText: lang.isArabic ? 'اسم العميل / المتجر (بالعربية) *' : 'Store Name (Arabic) *',
                      prefixIcon: const Icon(Icons.storefront),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? (lang.isArabic ? 'يرجى إدخال اسم المتجر' : 'Required') : null,
                  ),
                  const SizedBox(height: 10),

                  // Trade Name (English)
                  TextFormField(
                    controller: nameEnController,
                    decoration: InputDecoration(
                      labelText: lang.isArabic ? 'اسم المتجر بالإنجليزية' : 'Store Name (English)',
                      prefixIcon: const Icon(Icons.language),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Phone & District
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: lang.isArabic ? 'رقم الجوال *' : 'Phone *',
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? (lang.isArabic ? 'مطلوب' : 'Required') : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: districtController,
                          decoration: InputDecoration(
                            labelText: lang.isArabic ? 'الحي / المنطقة' : 'District',
                            prefixIcon: const Icon(Icons.location_on),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Credit Limit & Terms
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: creditLimitController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.isArabic ? 'سقف الائتمان (ر.س)' : 'Credit Limit (SAR)',
                            prefixIcon: const Icon(Icons.credit_score),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: creditDaysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.isArabic ? 'مهلة السداد (يوم)' : 'Grace Period (Days)',
                            prefixIcon: const Icon(Icons.schedule),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Optional VAT number
                  TextFormField(
                    controller: vatController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: lang.isArabic ? 'الرقم الضريبي للعميل (اختياري - 15 رقم)' : 'Customer VAT ID (Optional)',
                      prefixIcon: const Icon(Icons.verified),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          final db = DatabaseService();
                          final newCust = CustomerModel(
                            id: 'CUST-${DateTime.now().millisecondsSinceEpoch}',
                            nameAr: nameArController.text.trim(),
                            nameEn: nameEnController.text.trim().isNotEmpty
                                ? nameEnController.text.trim()
                                : nameArController.text.trim(),
                            phone: phoneController.text.trim(),
                            district: districtController.text.trim(),
                            routeArea: routeArea,
                            creditLimit: double.tryParse(creditLimitController.text) ?? 15000.0,
                            creditPeriodDays: int.tryParse(creditDaysController.text) ?? 30,
                            vatNumber: vatController.text.trim().isNotEmpty ? vatController.text.trim() : null,
                            currentBalance: 0.0,
                          );

                          db.addCustomerToVanRoute(vanId: vanId, customer: newCust);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang.isArabic
                                    ? 'تم تسجيل العميل "${newCust.nameAr}" وإضافته لمحطات المسار بنجاح!'
                                    : 'Customer "${newCust.nameAr}" added to route successfully!',
                              ),
                              backgroundColor: AppColors.saleGreen,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: Text(
                        lang.isArabic ? 'حفظ وإضافة للمسار الآن' : 'Save & Add to Route',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saleGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
  // Load Van Stock Modal
  // ---------------------------------------------------------------------------
  void _showLoadVanStockModal(BuildContext context, String vanId, DatabaseService db, AppLanguage lang) {
    ProductModel selectedProd = db.products.first;
    double qty = 10.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final mainWhStock = selectedProd.stockByWarehouse['WH-MAIN'] ?? 0.0;
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
                      lang.isArabic ? 'تحميل بضاعة من المستودع إلى السيارة' : 'Load Stock from Warehouse to Van',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ProductModel>(
                    isExpanded: true,
                    value: selectedProd,
                    decoration: InputDecoration(labelText: lang.isArabic ? 'اختر الصنف' : 'Select Product'),
                    items: db.products.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(lang.isArabic ? p.nameAr : p.nameEn, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (p) {
                      if (p != null) setModalState(() => selectedProd = p);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${lang.isArabic ? "المتاح في المستودع الرئيسي" : "Available in Main Warehouse"}: ${mainWhStock.toInt()} ${selectedProd.baseUnit}',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: '10',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: lang.isArabic ? 'الكمية المحمولة' : 'Quantity to Load'),
                    onChanged: (v) => qty = double.tryParse(v) ?? 10.0,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        db.transferStockToVan(
                          fromWarehouseId: 'WH-MAIN',
                          toVanId: vanId,
                          items: [
                            StockTransferItem(
                              productId: selectedProd.id,
                              productName: selectedProd.nameAr,
                              quantity: qty,
                              unit: selectedProd.baseUnit,
                            ),
                          ],
                          requestedByUserId: AuthService().currentUser.id,
                          requestedByUserName: AuthService().currentUser.name,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              lang.isArabic
                                  ? 'تم تحميل ${qty.toInt()} ${selectedProd.baseUnit} إلى السيارة بنجاح!'
                                  : 'Loaded ${qty.toInt()} ${selectedProd.baseUnit} to van successfully!',
                            ),
                            backgroundColor: AppColors.saleGreen,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: Text(lang.isArabic ? 'تأكيد تحميل البضاعة' : 'Confirm Stock Load'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saleGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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

  // Helper metric widgets
  Widget _buildStockValueCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildSettlementRow(String title, String value, {bool isPositive = false, bool isNegative = false}) {
    Color col = AppColors.textPrimary;
    if (isPositive) col = Colors.green.shade800;
    if (isNegative) col = Colors.red.shade800;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: col)),
      ],
    );
  }
}

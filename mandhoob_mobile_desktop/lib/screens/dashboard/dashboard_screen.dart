import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/invoice_model.dart';
import '../../models/payment_voucher_model.dart';
import '../sales/create_invoice_screen.dart';
import '../sales/invoice_detail_screen.dart';
import 'van_operations_hub_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToSales;
  final VoidCallback onNavigateToInventory;
  final VoidCallback onNavigateToCustomers;

  const DashboardScreen({
    super.key,
    required this.onNavigateToSales,
    required this.onNavigateToInventory,
    required this.onNavigateToCustomers,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AuthService(), AppLanguage()]),
      builder: (context, _) {
        final db = DatabaseService();
        final auth = AuthService();
        final lang = AppLanguage();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';
        final isSalesman = auth.currentRole == UserRole.salesman;
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 600;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(left: 14, right: 14, top: 12, bottom: 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User / Van Welcome Header (Mobile-Optimized Card)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1E40AF)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Icon(
                            isSalesman ? Icons.directions_car : Icons.business,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.currentUser.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isSalesman
                                    ? (lang.isArabic
                                        ? 'سيارة: ${auth.currentUser.assignedVanName}'
                                        : 'Van: ${auth.currentUser.assignedVanName}')
                                    : (lang.isArabic
                                        ? 'النظام المركزي للمبيعات والتوزيع'
                                        : 'Central Sales & Distribution'),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            lang.isArabic
                                ? auth.currentUser.roleDisplayNameAr.split(' ')[0]
                                : auth.currentUser.role.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // KPI Cards Grid (Mobile 2-column or Desktop 4-column)
              LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 650;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: isWide ? 1.7 : (isCompact ? 1.25 : 1.35),
                  children: [
                    _buildKpiCard(
                      title: lang.isArabic ? 'مبيعات اليوم' : "Today's Sales",
                      value: '${db.todaySalesTotal.toStringAsFixed(2)} $curr',
                      subtitle: lang.isArabic ? 'إجمالي المبيعات' : 'Total Generated Sales',
                      icon: Icons.trending_up,
                      color: AppColors.saleGreen,
                      onTap: onNavigateToSales,
                    ),
                    _buildKpiCard(
                      title: lang.isArabic ? 'نقد الصندوق' : 'Cash in Hand',
                      value: '${db.cashInHandTotal.toStringAsFixed(2)} $curr',
                      subtitle: isSalesman
                          ? (lang.isArabic ? 'نقد السيارة' : 'Van Float Cash')
                          : (lang.isArabic ? 'خزينة الفرع' : 'Branch Float Safe'),
                      icon: Icons.account_balance_wallet,
                      color: AppColors.primary,
                      onTap: () => _showCashBreakdownModal(context, db, lang, curr, isSalesman),
                    ),
                    if (!isSalesman) ...[
                      _buildKpiCard(
                        title: lang.isArabic ? 'غرفة العمليات' : 'Van Ops Hub',
                        value: '${db.salesmenProgress.length} ${lang.isArabic ? "سيارات نشطة" : "Active Vans"}',
                        subtitle: lang.isArabic ? 'متابعة المسارات' : 'Live Stop Tracking',
                        icon: Icons.alt_route,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const VanOperationsHubScreen()),
                          );
                        },
                      ),
                      _buildKpiCard(
                        title: lang.isArabic ? 'مستحقات العملاء' : "Receivables",
                        value: '${db.totalReceivables.toStringAsFixed(2)} $curr',
                        subtitle: lang.isArabic ? 'ذمم مدينة آجلة' : 'Customer Credit Due',
                        icon: Icons.arrow_downward,
                        color: AppColors.accent,
                        onTap: onNavigateToCustomers,
                      ),
                    ] else ...[
                      _buildKpiCard(
                        title: lang.isArabic ? 'بضاعة السيارة' : 'Van Stock Value',
                        value: '${db.getVanStockValue(auth.currentUser.assignedVanId ?? "VAN-01").toStringAsFixed(2)} $curr',
                        subtitle: lang.isArabic ? 'المخزون الميداني' : 'Active Mobile Stock',
                        icon: Icons.inventory_2,
                        color: AppColors.secondary,
                        onTap: onNavigateToInventory,
                      ),
                      _buildKpiCard(
                        title: lang.isArabic ? 'محطات اليوم' : "Today's Stops",
                        value: '${db.customers.where((c) => (c.routeArea?.contains("شمال") ?? false) || (c.routeArea?.contains("North") ?? false)).length} ${lang.isArabic ? "محطات" : "Route Stops"}',
                        subtitle: lang.isArabic ? 'مسار شمال الرياض' : 'Riyadh North Route',
                        icon: Icons.alt_route,
                        color: AppColors.accent,
                        onTap: onNavigateToCustomers,
                      ),
                    ]
                  ],
                );
              }),

              const SizedBox(height: 18),

              // Quick Actions Bar
              Text(
                lang.isArabic ? 'إجراءات سريعة' : 'Quick Actions',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionButton(
                      label: lang.isArabic ? '+ فاتورة جديدة' : '+ New Invoice',
                      icon: Icons.receipt,
                      color: AppColors.saleGreen,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateInvoiceScreen(
                              defaultType: InvoiceType.simplifiedTaxInvoice,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      label: lang.isArabic ? '+ بيع فوري' : '+ Spot Sale',
                      icon: Icons.directions_car,
                      color: AppColors.primary,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateInvoiceScreen(
                              defaultType: InvoiceType.simplifiedTaxInvoice,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      label: lang.isArabic ? 'تحميل بضاعة' : 'Load Van',
                      icon: Icons.move_to_inbox,
                      color: AppColors.secondary,
                      onPressed: onNavigateToInventory,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      label: lang.isArabic ? 'سند تحصيل' : 'Payment In',
                      icon: Icons.payments,
                      color: Colors.teal,
                      onPressed: onNavigateToCustomers,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Recent Transactions Stream
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.isArabic ? 'أحدث الفواتير والمعاملات' : 'Recent Invoices',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: onNavigateToSales,
                    child: Text(lang.isArabic ? 'عرض الكل' : 'View All'),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (db.invoices.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    lang.isArabic ? 'لا توجد فواتير حتى الآن' : 'No invoices yet',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: db.invoices.take(4).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final inv = db.invoices[index];
                    final isCredit = inv.paymentMethod == PaymentMethod.credit;
                    final custName = lang.isArabic ? inv.customerNameAr : inv.customerNameEn;

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      elevation: 0.5,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InvoiceDetailScreen(invoice: inv),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: inv.type == InvoiceType.salesReturn
                                        ? AppColors.expenseRed.withOpacity(0.12)
                                        : AppColors.saleGreen.withOpacity(0.12),
                                    child: Icon(
                                      inv.type == InvoiceType.salesReturn ? Icons.assignment_return : Icons.receipt,
                                      size: 16,
                                      color: inv.type == InvoiceType.salesReturn ? AppColors.expenseRed : AppColors.saleGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            inv.invoiceNumber,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: isCredit ? AppColors.badgePartialBg : AppColors.badgePaidBg,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isCredit
                                                  ? (lang.isArabic ? 'آجل' : 'Credit')
                                                  : (lang.isArabic ? 'نقداً' : 'Cash'),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isCredit ? AppColors.badgePartialText : AppColors.badgePaidText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        custName,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${inv.grandTotal.toStringAsFixed(2)} $curr',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    inv.invoiceDate.toLocal().toString().substring(5, 16),
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(icon, color: color, size: 14),
                  ),
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
      ),
    );
  }

  void _showCashBreakdownModal(
    BuildContext context,
    DatabaseService db,
    AppLanguage lang,
    String curr,
    bool isSalesman,
  ) {
    final cashSales = db.invoices
        .where((i) => i.paymentMethod == PaymentMethod.cash && i.type != InvoiceType.salesReturn)
        .fold(0.0, (sum, i) => sum + i.grandTotal);

    final cashCollections = db.paymentVouchers
        .where((v) => v.paymentMode == VoucherPaymentMode.cash)
        .fold(0.0, (sum, v) => sum + v.amount);

    final cashExpenses = db.expenses
        .where((e) => e.paymentMode.toLowerCase().contains('cash') || e.paymentMode.contains('نقد'))
        .fold(0.0, (sum, e) => sum + e.totalWithVat);

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
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        lang.isArabic ? 'تفاصيل نقد الصندوق والعهدة الحالية' : 'Cash in Hand & Float Breakdown',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildCashRow(lang.isArabic ? 'الرصيد الافتتاحي للعهدة (Opening Float):' : 'Opening Float:', '2,500.00 $curr', Colors.black87),
                const SizedBox(height: 8),
                _buildCashRow(lang.isArabic ? '+ مبيعات نقدية محصلة (Cash Sales):' : '+ Cash Sales:', '+ ${cashSales.toStringAsFixed(2)} $curr', Colors.green),
                const SizedBox(height: 8),
                _buildCashRow(lang.isArabic ? '+ تحصيلات سندات القبض (Collections):' : '+ Cash Collections:', '+ ${cashCollections.toStringAsFixed(2)} $curr', Colors.green),
                const SizedBox(height: 8),
                _buildCashRow(lang.isArabic ? '- مصروفات مسددة نقداً (Cash Expenses):' : '- Cash Expenses:', '- ${cashExpenses.toStringAsFixed(2)} $curr', Colors.red),
                const Divider(height: 20),
                _buildCashRow(
                  lang.isArabic ? 'صافي النقد الفعلي بالصندوق (Net Cash):' : 'Net Cash in Hand:',
                  '${db.cashInHandTotal.toStringAsFixed(2)} $curr',
                  AppColors.primary,
                  isBold: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCashRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isBold ? 13 : 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: isBold ? 15 : 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

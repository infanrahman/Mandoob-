import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/customer_model.dart';
import '../../models/invoice_model.dart';
import '../../services/database_service.dart';
import '../sales/invoice_detail_screen.dart';
import '../sales/create_invoice_screen.dart';
import 'payment_in_dialog.dart';

class CustomerDetailScreen extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AppLanguage()]),
      builder: (context, _) {
        final db = DatabaseService();
        final lang = AppLanguage();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';

        // Fetch refreshed customer object
        final currentCust = db.customers.firstWhere(
          (c) => c.id == customer.id,
          orElse: () => customer,
        );

        final customerInvoices = db.invoices.where((inv) => inv.customerId == currentCust.id).toList();
        final customerPayments = db.paymentVouchers.where((v) => v.partyId == currentCust.id).toList();
        final aging = db.getCustomerAging(currentCust.id);

        final creditUsedRatio = currentCust.creditUtilizationRatio;
        final isNearLimit = creditUsedRatio >= 0.85;

        return Scaffold(
          appBar: AppBar(
            title: Text(lang.isArabic ? currentCust.nameAr : currentCust.nameEn),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: lang.isArabic ? 'إرسال تذكير سداد عبر الواتساب' : 'Send WhatsApp Payment Reminder',
                onPressed: () => _sendWhatsAppReminder(context, currentCust, lang),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Credit Limit & Utilization Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.isArabic ? currentCust.nameAr : currentCust.nameEn,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  lang.isArabic ? currentCust.nameEn : currentCust.nameAr,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CreateInvoiceScreen(
                                          defaultType: currentCust.isVatRegistered
                                              ? InvoiceType.taxInvoice
                                              : InvoiceType.simplifiedTaxInvoice,
                                          preselectedCustomer: currentCust,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.receipt_long, size: 16),
                                  label: Text(lang.isArabic ? '+ فاتورة جديدة' : '+ New Invoice'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => PaymentInDialog(customer: currentCust),
                                    );
                                  },
                                  icon: const Icon(Icons.payments, size: 16),
                                  label: Text(lang.isArabic ? 'سند قبض نقد' : 'Cash Receipt In'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.saleGreen,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Divider(height: 20),

                        // Credit Gauge & Financial Metrics
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.isArabic ? 'المستحق' : 'Due Balance',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${currentCust.currentBalance.toStringAsFixed(2)} $curr',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: currentCust.currentBalance > 0 ? AppColors.expenseRed : Colors.green,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    lang.isArabic ? 'سقف الائتمان' : 'Credit Limit',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${currentCust.creditLimit.toStringAsFixed(0)} $curr',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    lang.isArabic ? 'المتبقي' : 'Available',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${currentCust.availableCredit.toStringAsFixed(2)} $curr',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isNearLimit ? AppColors.expenseRed : Colors.green.shade700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Credit Utilization Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: creditUsedRatio,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              creditUsedRatio > 0.9
                                  ? AppColors.expenseRed
                                  : (creditUsedRatio > 0.7 ? AppColors.accent : AppColors.saleGreen),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${lang.isArabic ? "نسبة استغلال الائتمان" : "Credit Utilization"}: ${(creditUsedRatio * 100).toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 11, color: isNearLimit ? AppColors.expenseRed : AppColors.textSecondary),
                            ),
                            Text(
                              '${lang.isArabic ? "فترة السماح" : "Grace Period"}: ${currentCust.creditPeriodDays} ${lang.isArabic ? "يوم" : "Days"}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 2. Debt Aging Analysis Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.history, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              lang.isArabic ? 'تحليل أعمار الديون (Aging Analysis)' : 'Debt Aging Analysis',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAgingBox(lang.isArabic ? '0 - 30 يوم' : '0-30 Days', aging['0_30']!, Colors.green, curr),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildAgingBox(lang.isArabic ? '31 - 60 يوم' : '31-60 Days', aging['31_60']!, Colors.amber.shade800, curr),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildAgingBox(lang.isArabic ? '61 - 90 يوم' : '61-90 Days', aging['61_90']!, Colors.deepOrange, curr),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildAgingBox(lang.isArabic ? '90+ يوم (متأخر)' : '90+ Days (Overdue)', aging['90_plus']!, Colors.red.shade900, curr),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Quick WhatsApp Reminder Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _sendWhatsAppReminder(context, currentCust, lang),
                    icon: const Icon(Icons.chat, color: Colors.green),
                    label: Text(lang.isArabic ? 'إرسال إشعار تذكير بالسداد والمطالبة عبر WhatsApp' : 'Send Payment Reminder via WhatsApp'),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Statement of Account / Ledgers Table
                Text(
                  lang.isArabic ? 'كشف الحساب وسجل السندات والفواتير / Ledger' : 'Statement of Account / Ledger & Vouchers',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),

                if (customerInvoices.isEmpty && customerPayments.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Center(child: Text(lang.isArabic ? 'لا توجد حركات مسجلة لهذا العميل' : 'No transactions recorded for this customer')),
                  )
                else ...[
                  // Payment Vouchers First
                  ...customerPayments.map((voucher) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFDCFCE7),
                            child: Icon(Icons.arrow_downward, color: Colors.green),
                          ),
                          title: Row(
                            children: [
                              Text(voucher.voucherNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  lang.isArabic ? voucher.typeDisplayNameAr : 'Cash Receipt',
                                  style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text('${voucher.date.toString().substring(0, 16)} • ${lang.isArabic ? voucher.paymentModeDisplayNameAr : "Cash"}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '- ${voucher.amount.toStringAsFixed(2)} $curr',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                              ),
                              Text(lang.isArabic ? 'سداد (دائن)' : 'Payment In', style: const TextStyle(fontSize: 11, color: Colors.green)),
                            ],
                          ),
                        ),
                      )),

                  // Invoices
                  ...customerInvoices.map((inv) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEFF6FF),
                            child: Icon(Icons.receipt, color: AppColors.primary),
                          ),
                          title: Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${inv.invoiceDate.toString().substring(0, 16)} • ${inv.warehouseName}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+ ${inv.grandTotal.toStringAsFixed(2)} $curr',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                              ),
                              Text(
                                inv.paymentMethod == PaymentMethod.credit
                                    ? (lang.isArabic ? 'فاتورة آجلة (مدين)' : 'Credit (Debit)')
                                    : (lang.isArabic ? 'مسددة نقد' : 'Paid Cash'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: inv.paymentMethod == PaymentMethod.credit ? AppColors.expenseRed : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: inv)),
                            );
                          },
                        ),
                      )),
                ],
              ],
            ),
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

  void _sendWhatsAppReminder(BuildContext context, CustomerModel cust, AppLanguage lang) {
    final curr = lang.isArabic ? 'ر.س' : 'SAR';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang.isArabic
              ? 'تم تجهيز رسالة المطالبة بالرصيد المستحق (${cust.currentBalance.toStringAsFixed(2)} $curr) لرقم ${cust.phone}!'
              : 'Payment reminder for balance (${cust.currentBalance.toStringAsFixed(2)} $curr) prepared for ${cust.phone}!',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/supplier_model.dart';
import '../../services/database_service.dart';
import 'payment_out_dialog.dart';

class SupplierDetailScreen extends StatelessWidget {
  final SupplierModel supplier;

  const SupplierDetailScreen({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AppLanguage()]),
      builder: (context, _) {
        final db = DatabaseService();
        final lang = AppLanguage();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';

        final currentSupp = db.suppliers.firstWhere(
          (s) => s.id == supplier.id,
          orElse: () => supplier,
        );

        final supplierPayments = db.paymentVouchers.where((v) => v.partyId == currentSupp.id).toList();
        final creditUsedRatio = currentSupp.creditUtilizationRatio;

        return Scaffold(
          appBar: AppBar(
            title: Text(lang.isArabic ? currentSupp.nameAr : currentSupp.nameEn),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Supplier Profile & Payables Card
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
                                  lang.isArabic ? currentSupp.nameAr : currentSupp.nameEn,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  lang.isArabic ? currentSupp.nameEn : currentSupp.nameAr,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => PaymentOutDialog(supplier: currentSupp),
                                );
                              },
                              icon: const Icon(Icons.payment, size: 16),
                              label: Text(lang.isArabic ? 'سند صرف' : 'Payment Out'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.purchaseBlue,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.isArabic ? 'المستحق للمورد' : 'Payable',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${currentSupp.currentBalance.toStringAsFixed(2)} $curr',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.purchaseBlue),
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
                                    '${currentSupp.creditLimit.toStringAsFixed(0)} $curr',
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
                                    lang.isArabic ? 'المتبقي للشراء' : 'Available',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${currentSupp.availableCredit.toStringAsFixed(2)} $curr',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green.shade700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: creditUsedRatio,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purchaseBlue),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${lang.isArabic ? "نسبة السقف المستخدم" : "Credit Utilized"}: ${(creditUsedRatio * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Text(
                              '${lang.isArabic ? "شروط السداد" : "Credit Terms"}: ${currentSupp.creditPeriodDays} ${lang.isArabic ? "يوم" : "Days"}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),

                        const Divider(height: 20),

                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(currentSupp.phone),
                            const Spacer(),
                            if (currentSupp.vatNumber != null)
                              Text('VAT: ${currentSupp.vatNumber}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Statement of Account / Payments History
                Text(
                  lang.isArabic ? 'كشف حساب المورد وحركات السداد / Ledger' : 'Supplier Statement of Account / Payments',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),

                if (supplierPayments.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Center(child: Text(lang.isArabic ? 'لا توجد سندات صرف مسجلة لهذا المورد' : 'No payment vouchers recorded for this supplier')),
                  )
                else
                  ...supplierPayments.map((voucher) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEFF6FF),
                            child: Icon(Icons.arrow_upward, color: AppColors.purchaseBlue),
                          ),
                          title: Row(
                            children: [
                              Text(voucher.voucherNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  lang.isArabic ? voucher.typeDisplayNameAr : 'Payment Out',
                                  style: const TextStyle(fontSize: 10, color: AppColors.purchaseBlue, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text('${voucher.date.toString().substring(0, 16)} • ${lang.isArabic ? voucher.paymentModeDisplayNameAr : "Transfer"}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '- ${voucher.amount.toStringAsFixed(2)} $curr',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purchaseBlue, fontSize: 14),
                              ),
                              Text(
                                lang.isArabic ? 'سداد دفعة (مدين)' : 'Payment Out (Debit)',
                                style: const TextStyle(fontSize: 11, color: AppColors.purchaseBlue),
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }
}

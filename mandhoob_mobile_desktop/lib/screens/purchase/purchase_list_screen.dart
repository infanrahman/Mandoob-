import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/database_service.dart';
import '../../models/supplier_model.dart';
import '../suppliers/supplier_detail_screen.dart';
import '../suppliers/payment_out_dialog.dart';

class PurchaseListScreen extends StatelessWidget {
  const PurchaseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AppLanguage()]),
      builder: (context, _) {
        final db = DatabaseService();
        final lang = AppLanguage();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';

        return Scaffold(
          appBar: AppBar(
            title: Text(lang.isArabic ? 'المشتريات والموردين' : 'Purchases & Suppliers'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payables Banner
                Container(
                  padding: const EdgeInsets.all(16),
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
                            const Icon(Icons.inventory, color: AppColors.purchaseBlue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lang.isArabic
                                    ? "إجمالي المستحقات للموردين:"
                                    : "Total Payables to Suppliers:",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${db.totalPayables.toStringAsFixed(2)} $curr',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.purchaseBlue),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  lang.isArabic
                      ? 'قائمة الموردين المعتمدين وسقف الائتمان'
                      : 'Approved Suppliers & Credit Terms',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: db.suppliers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final supp = db.suppliers[index];
                    final suppName = lang.isArabic ? supp.nameAr : supp.nameEn;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.purchaseBlue.withOpacity(0.1),
                          child: const Icon(Icons.business, color: AppColors.purchaseBlue),
                        ),
                        title: Text(suppName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${lang.isArabic ? "هاتف" : "Phone"}: ${supp.phone} • ${lang.isArabic ? "السجل" : "CR"}: ${supp.crNumber}'),
                            Text(
                              '${lang.isArabic ? "سقف الائتمان" : "Credit Limit"}: ${supp.creditLimit.toStringAsFixed(0)} $curr • ${lang.isArabic ? "مهلة" : "Terms"}: ${supp.creditPeriodDays} ${lang.isArabic ? "يوم" : "Days"}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${supp.currentBalance.toStringAsFixed(2)} $curr',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purchaseBlue),
                            ),
                            Text(
                              lang.isArabic ? 'رصيد دائن' : 'Payable Due',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SupplierDetailScreen(supplier: supp),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              if (db.suppliers.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (_) => PaymentOutDialog(supplier: db.suppliers.first),
                );
              }
            },
            backgroundColor: AppColors.purchaseBlue,
            icon: const Icon(Icons.payment, color: Colors.white),
            label: Text(lang.isArabic ? 'سند صرف للمورد' : 'Supplier Payment Out', style: const TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }
}

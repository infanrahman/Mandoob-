import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/customer_model.dart';
import '../../models/payment_voucher_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class PaymentInDialog extends StatefulWidget {
  final CustomerModel customer;

  const PaymentInDialog({super.key, required this.customer});

  @override
  State<PaymentInDialog> createState() => _PaymentInDialogState();
}

class _PaymentInDialogState extends State<PaymentInDialog> {
  final _formKey = GlobalKey<FormState>();
  double _amount = 0.0;
  VoucherPaymentMode _paymentMode = VoucherPaymentMode.cash;
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amount = widget.customer.currentBalance > 0 ? widget.customer.currentBalance : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguage();
    final curr = lang.isArabic ? 'ر.س' : 'SAR';
    final balanceAfter = (widget.customer.currentBalance - _amount).clamp(0.0, 9999999.0);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFDCFCE7),
            child: Icon(Icons.arrow_downward, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.isArabic ? 'سند قبض تحصيل نقد / مدى' : 'Cash / Mada Receipt In Voucher',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  lang.isArabic ? widget.customer.nameAr : widget.customer.nameEn,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Comparison Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.isArabic ? 'الرصيد الحالي:' : 'Current Balance:',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${widget.customer.currentBalance.toStringAsFixed(2)} $curr',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.expenseRed, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.arrow_forward, color: AppColors.textMuted, size: 16),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            lang.isArabic ? 'الرصيد بعد السداد:' : 'Balance After Payment:',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${balanceAfter.toStringAsFixed(2)} $curr',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: balanceAfter == 0 ? Colors.green : AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Amount Field
              TextFormField(
                initialValue: _amount > 0 ? _amount.toStringAsFixed(2) : '',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: lang.isArabic ? 'المبلغ المحصل ($curr) *' : 'Amount Collected ($curr) *',
                  prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                ),
                validator: (val) {
                  final parsed = double.tryParse(val ?? '');
                  if (parsed == null || parsed <= 0) {
                    return lang.isArabic ? 'يرجى إدخال مبلغ صحيح' : 'Please enter a valid amount';
                  }
                  return null;
                },
                onChanged: (val) {
                  setState(() {
                    _amount = double.tryParse(val) ?? 0.0;
                  });
                },
              ),

              const SizedBox(height: 12),

              // Payment Mode Selector
              Text(
                lang.isArabic ? 'طريقة السداد / Payment Method' : 'Payment Method',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<VoucherPaymentMode>(
                isExpanded: true,
                value: _paymentMode,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: [
                  DropdownMenuItem(value: VoucherPaymentMode.cash, child: Text(lang.isArabic ? 'نقداً (Cash)' : 'Cash', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: VoucherPaymentMode.madaCard, child: Text(lang.isArabic ? 'شبكة / مدى (Mada)' : 'Mada / Card', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: VoucherPaymentMode.bankTransfer, child: Text(lang.isArabic ? 'تحويل بنكي (Bank Transfer)' : 'Bank Transfer', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: VoucherPaymentMode.cheque, child: Text(lang.isArabic ? 'شيك بنكي (Cheque)' : 'Cheque', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (mode) {
                  if (mode != null) setState(() => _paymentMode = mode);
                },
              ),

              if (_paymentMode == VoucherPaymentMode.bankTransfer || _paymentMode == VoucherPaymentMode.cheque) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _refController,
                  decoration: InputDecoration(
                    labelText: lang.isArabic ? 'رقم الحوالة / رقم الشيك البنكي' : 'Bank Transfer / Cheque Reference #',
                  ),
                ),
              ],

              const SizedBox(height: 10),

              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: lang.isArabic ? 'ملاحظات وسند الإيداع' : 'Deposit & Reference Notes',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(lang.isArabic ? 'إلغاء' : 'Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final auth = AuthService();
              final db = DatabaseService();

              final voucher = PaymentVoucherModel(
                id: 'VCT-${DateTime.now().millisecondsSinceEpoch}',
                voucherNumber: 'RCT-${DateTime.now().year}-${db.paymentVouchers.length + 101}',
                type: VoucherType.paymentIn,
                partyId: widget.customer.id,
                partyNameAr: widget.customer.nameAr,
                partyNameEn: widget.customer.nameEn,
                amount: _amount,
                date: DateTime.now(),
                paymentMode: _paymentMode,
                referenceNumber: _refController.text.isNotEmpty ? _refController.text : null,
                vanId: auth.currentUser.assignedVanId,
                collectedByUserId: auth.currentUser.id,
                collectedByUserName: auth.currentUser.name,
                notes: _notesController.text,
              );

              db.addPaymentIn(voucher);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    lang.isArabic
                        ? 'تم تحصيل مبلغ ${_amount.toStringAsFixed(2)} $curr وتحديث حساب العميل بنجاح!'
                        : 'Collected ${_amount.toStringAsFixed(2)} $curr and updated customer ledger successfully!',
                  ),
                  backgroundColor: AppColors.saleGreen,
                ),
              );
            }
          },
          icon: const Icon(Icons.check, size: 16),
          label: Text(lang.isArabic ? 'تأكيد التحصيل والترحيل' : 'Confirm & Post Receipt'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.saleGreen),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/supplier_model.dart';
import '../../models/payment_voucher_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class PaymentOutDialog extends StatefulWidget {
  final SupplierModel supplier;

  const PaymentOutDialog({super.key, required this.supplier});

  @override
  State<PaymentOutDialog> createState() => _PaymentOutDialogState();
}

class _PaymentOutDialogState extends State<PaymentOutDialog> {
  final _formKey = GlobalKey<FormState>();
  double _amount = 0.0;
  VoucherPaymentMode _paymentMode = VoucherPaymentMode.bankTransfer;
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amount = widget.supplier.currentBalance > 0 ? widget.supplier.currentBalance : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguage();
    final curr = lang.isArabic ? 'ر.س' : 'SAR';
    final balanceAfter = (widget.supplier.currentBalance - _amount).clamp(0.0, 9999999.0);

    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFEFF6FF),
            child: Icon(Icons.arrow_upward, color: AppColors.purchaseBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.isArabic ? 'سند صرف وسداد مورد' : 'Supplier Payment Out Voucher',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  lang.isArabic ? widget.supplier.nameAr : widget.supplier.nameEn,
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
                            lang.isArabic ? 'المستحق الحالي:' : 'Current Due:',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${widget.supplier.currentBalance.toStringAsFixed(2)} $curr',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purchaseBlue, fontSize: 13),
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
                            lang.isArabic ? 'المتبقي بعد الصرف:' : 'Balance After Payment:',
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
                  labelText: lang.isArabic ? 'مبلغ السداد للمورد ($curr) *' : 'Payment Amount ($curr) *',
                  prefixIcon: const Icon(Icons.attach_money, color: AppColors.purchaseBlue),
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
                  DropdownMenuItem(value: VoucherPaymentMode.bankTransfer, child: Text(lang.isArabic ? 'تحويل بنكي (Bank Transfer)' : 'Bank Transfer', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: VoucherPaymentMode.cheque, child: Text(lang.isArabic ? 'شيك بنكي (Cheque)' : 'Cheque', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: VoucherPaymentMode.cash, child: Text(lang.isArabic ? 'نقداً من عهدة المندوب (Cash)' : 'Cash from Float', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (mode) {
                  if (mode != null) setState(() => _paymentMode = mode);
                },
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _refController,
                decoration: InputDecoration(
                  labelText: lang.isArabic ? 'رقم الحوالة البنكية / رقم الشيك' : 'Bank Transfer / Cheque Reference #',
                ),
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: lang.isArabic ? 'ملاحظات أمر الصرف' : 'Payment Notes',
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
                id: 'VCT-OUT-${DateTime.now().millisecondsSinceEpoch}',
                voucherNumber: 'PV-${DateTime.now().year}-${db.paymentVouchers.length + 201}',
                type: VoucherType.paymentOut,
                partyId: widget.supplier.id,
                partyNameAr: widget.supplier.nameAr,
                partyNameEn: widget.supplier.nameEn,
                amount: _amount,
                date: DateTime.now(),
                paymentMode: _paymentMode,
                referenceNumber: _refController.text.isNotEmpty ? _refController.text : null,
                vanId: auth.currentUser.assignedVanId,
                collectedByUserId: auth.currentUser.id,
                collectedByUserName: auth.currentUser.name,
                notes: _notesController.text,
              );

              db.addPaymentOut(voucher);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    lang.isArabic
                        ? 'تم صرف مبلغ ${_amount.toStringAsFixed(2)} $curr للمورد بنجاح!'
                        : 'Disbursed ${_amount.toStringAsFixed(2)} $curr to supplier successfully!',
                  ),
                  backgroundColor: AppColors.purchaseBlue,
                ),
              );
            }
          },
          icon: const Icon(Icons.check, size: 16),
          label: Text(lang.isArabic ? 'تأكيد الصرف والترحيل' : 'Confirm & Post Payment'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.purchaseBlue),
        ),
      ],
    );
  }
}

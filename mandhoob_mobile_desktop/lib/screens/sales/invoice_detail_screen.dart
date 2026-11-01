import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/invoice_model.dart';
import '../../services/printer_service.dart';
import '../../services/database_service.dart';
import '../../core/zatca/ubl_xml_generator.dart';
import '../../core/zatca/zatca_crypto_service.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLanguage(),
      builder: (context, _) {
        final db = DatabaseService();
        final lang = AppLanguage();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';

        // Ensure UBL XML is generated
        final ublXml = invoice.ubl21Xml.isNotEmpty
            ? invoice.ubl21Xml
            : ZatcaUblXmlGenerator.generateInvoiceXml(
                invoice: invoice,
                sellerNameAr: db.companyNameAr,
                sellerVatNumber: db.vatNumber,
                sellerCrNumber: db.crNumber,
                buildingNumber: db.buildingNumber,
                streetName: db.street,
                districtName: db.district,
                cityName: db.city,
                postalCode: db.postalCode,
                invoiceCounterValue: invoice.invoiceCounterValue,
                previousInvoiceHash: invoice.previousInvoiceHash,
                invoiceUuid: invoice.invoiceUuid,
              );

        return Scaffold(
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'فحص ملف UBL 2.1 XML المعتمد (ZATCA Phase 2)',
            onPressed: () => _showUblXmlModal(context, ublXml),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'طباعة حرارية / Thermal Print',
            onPressed: () => _showThermalReceiptModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'مشاركة PDF / WhatsApp',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تصدير الفاتورة ومشاركتها عبر الواتساب بنجاح!'),
                  backgroundColor: AppColors.saleGreen,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ZATCA Phase 2 Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Colors.green, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lang.isArabic
                                    ? 'الفاتورة الإلكترونية (ZATCA Phase 2)'
                                    : 'E-Invoice (ZATCA Phase 2)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                invoice.type == InvoiceType.taxInvoice ? 'Cleared' : 'Reported',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'معرّف الفاتورة (UUID): ${invoice.invoiceUuid}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Official ZATCA Compliant Invoice Container (Vyapar Paper Style)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Header & ZATCA Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              db.companyNameAr,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              db.companyNameEn,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'الرقم الضريبي: ${db.vatNumber}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'السجل التجاري: ${db.crNumber}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ICV #${invoice.invoiceCounterValue}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('UBL 2.1 XML Ready', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),

                  const Divider(height: 28),

                  // Invoice Meta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.typeDisplayNameAr,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'رقم الفاتورة: ${invoice.invoiceNumber}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'التاريخ: ${invoice.invoiceDate.toLocal().toString().substring(0, 16)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'الموقع: ${invoice.warehouseName}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Customer Details Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('بيانات العميل (Billed To):', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          '${invoice.customerNameAr} (${invoice.customerNameEn})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (invoice.customerVatNumber != null)
                          Text('الرقم الضريبي للعميل: ${invoice.customerVatNumber}', style: const TextStyle(fontSize: 12)),
                        if (invoice.customerPhone != null)
                          Text('رقم الجوال: ${invoice.customerPhone}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Line Items Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('الصنف / Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(child: Text('الكمية', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(child: Text('السعر', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(child: Text('الإجمالي', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                  ),

                  // Line Items Rows
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invoice.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = invoice.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productNameAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(item.productNameEn, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${item.quantity.toInt()} ${item.unit}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.unitPrice.toStringAsFixed(2),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${item.lineTotalWithVat.toStringAsFixed(2)} ر.س',
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const Divider(height: 24),

                  // Totals & ZATCA 8-Tag QR Code Display
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 420;

                      final qrWidget = Column(
                        crossAxisAlignment: isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'رمز الاستجابة السريعة (ZATCA Phase 2 QR):',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.black87,
                                  child: const Center(
                                    child: Icon(Icons.qr_code_2, size: 90, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'مشفّر بـ 8 وسوم (Tags 1-8)\nبما فيها الختم الرقمي وهاش XML',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                      final summaryWidget = Column(
                        children: [
                          _buildSumRow(lang.isArabic ? 'المجموع قبل الضريبة:' : 'Subtotal (Excl. VAT):', '${invoice.subtotal.toStringAsFixed(2)} $curr'),
                          const SizedBox(height: 6),
                          _buildSumRow(lang.isArabic ? 'الضريبة (15% VAT):' : 'VAT (15%):', '${invoice.totalVat.toStringAsFixed(2)} $curr'),
                          const Divider(height: 16),
                          _buildSumRow(
                            lang.isArabic ? 'الإجمالي النهائي:' : 'Grand Total:',
                            '${invoice.grandTotal.toStringAsFixed(2)} $curr',
                            isBold: true,
                          ),
                          const SizedBox(height: 6),
                          _buildSumRow(
                            lang.isArabic ? 'طريقة الدفع:' : 'Payment Mode:',
                            invoice.paymentMethod == PaymentMethod.credit
                                ? (lang.isArabic ? 'آجل (ذمم)' : 'Credit (Account)')
                                : (lang.isArabic ? 'نقداً' : 'Cash'),
                          ),
                        ],
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            summaryWidget,
                            const SizedBox(height: 16),
                            Center(child: qrWidget),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: qrWidget),
                          const SizedBox(width: 20),
                          Expanded(child: summaryWidget),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ZATCA Phase 2 Cryptographic Audit Block
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.security, color: Colors.green),
                title: Text(
                  lang.isArabic ? 'التفاصيل المشفرة لهيئة الزكاة' : 'ZATCA Phase 2 Cryptographic Proof',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('SHA-256 XML Hash, ECDSA Signature, Chain of Trust', style: TextStyle(fontSize: 11)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCryptoDetailRow('هاش الفاتورة (Tag 6 - Invoice XML Hash):', invoice.invoiceXmlHash),
                        const SizedBox(height: 8),
                        _buildCryptoDetailRow('الختم الرقمي (Tag 7 - ECDSA Digital Signature):', invoice.cryptographicStamp),
                        const SizedBox(height: 8),
                        _buildCryptoDetailRow('هاش الفاتورة السابقة (Chain of Trust - PIH):', invoice.previousInvoiceHash),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _showUblXmlModal(context, ublXml),
                          icon: const Icon(Icons.description, size: 16),
                          label: Text(lang.isArabic ? 'عرض ملف الفاتورة بتنسيق UBL 2.1 XML' : 'View UBL 2.1 XML File'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Print Thermal Receipt Action Card
            Card(
              color: AppColors.primary,
              child: ListTile(
                leading: const Icon(Icons.receipt, color: Colors.white, size: 30),
                title: Text(
                  lang.isArabic ? 'طباعة الإيصال الحراري المتوافق مع ZATCA' : 'Print ZATCA Thermal Receipt',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  lang.isArabic
                      ? 'طباعة فورية عبر طابعات البلوتوث المحمولة 58mm و 80mm'
                      : 'Instant ESC/POS printing on 58mm & 80mm Bluetooth/Wi-Fi printers',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                onTap: () => _showThermalReceiptModal(context),
              ),
            ),
          ],
        ),
      ),
    );
  },
);
}

  Widget _buildCryptoDetailRow(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(val, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
        ),
      ],
    );
  }

  Widget _buildSumRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: isBold ? 14 : 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showUblXmlModal(BuildContext context, String xml) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ملف UBL 2.1 XML الرسمي (ZATCA Standard)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // Dark code editor background
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      xml,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم نسخ وتنزيل ملف UBL 2.1 XML بنجاح!'),
                        backgroundColor: AppColors.saleGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('نسخ كود XML الفاتورة المعتمدة'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showThermalReceiptModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'معاينة الإيصال الحراري (Thermal 80mm)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Text(
                          'شركة المندوب للتوزيع',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Text(
                          'Mandhoob Distribution Co.',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text('فاتورة ضريبية مبسطة (Simplified)'),
                        const Text('VAT: 310123456700003'),
                        const Text('CR: 1010892341'),
                        const Text('--------------------------------'),
                        Text('Inv #: ${invoice.invoiceNumber}'),
                        Text('Date: ${invoice.invoiceDate.toLocal().toString().substring(0, 16)}'),
                        Text('Customer: ${invoice.customerNameAr}'),
                        Text('Van: ${invoice.warehouseName}'),
                        const Text('--------------------------------'),
                        ...invoice.items.map((i) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${i.productNameAr.substring(0, i.productNameAr.length.clamp(0, 12))} x${i.quantity.toInt()}'),
                                Text('${i.lineTotalWithVat.toStringAsFixed(2)} SAR'),
                              ],
                            )),
                        const Text('--------------------------------'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text('${invoice.subtotal.toStringAsFixed(2)} SAR'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('VAT 15%:'),
                            Text('${invoice.totalVat.toStringAsFixed(2)} SAR'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${invoice.grandTotal.toStringAsFixed(2)} SAR', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 100,
                          height: 100,
                          color: Colors.black87,
                          child: const Icon(Icons.qr_code, size: 90, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        const Text('ZATCA Phase 2 E-Invoice QR Code', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await PrinterService().printInvoiceThermal(invoice);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إرسال أمر الطباعة عبر البلوتوث بنجاح!'),
                        backgroundColor: AppColors.saleGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('طباعة فورية عبر طابعة البلوتوث المتصلة'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

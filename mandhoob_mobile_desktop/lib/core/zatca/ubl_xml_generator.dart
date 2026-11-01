import '../../models/invoice_model.dart';
import '../../models/invoice_item_model.dart';

/// ZATCA Phase 2 Official UBL 2.1 XML Invoice Generator
/// Compliant with Saudi Zakat, Tax and Customs Authority (هيئة الزكاة والضريبة والجمارك)
class ZatcaUblXmlGenerator {
  /// Generate a compliant UBL 2.1 XML string for ZATCA Phase 2 Clearance/Reporting
  static String generateInvoiceXml({
    required InvoiceModel invoice,
    required String sellerNameAr,
    required String sellerVatNumber,
    required String sellerCrNumber,
    required String buildingNumber,
    required String streetName,
    required String districtName,
    required String cityName,
    required String postalCode,
    required int invoiceCounterValue, // ICV: 1, 2, 3...
    required String previousInvoiceHash, // PIH: SHA-256 base64 of previous invoice
    String? invoiceUuid,
  }) {
    final uuid = invoiceUuid ?? 'c75a4094-a75d-508b-c6cd-77af98124401';
    final issueDate = invoice.invoiceDate.toUtc().toIso8601String().substring(0, 10);
    final issueTime = invoice.invoiceDate.toUtc().toIso8601String().substring(11, 19);

    final isB2B = invoice.type == InvoiceType.taxInvoice;
    final profileId = isB2B ? 'clearance:1.0' : 'reporting:1.0';
    final invoiceSubtypeCode = isB2B ? '0100000' : '0200000'; // Standard (01) vs Simplified (02)

    final invoiceTypeCode = invoice.type == InvoiceType.salesReturn ? '381' : '388';

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
        '<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" '
        'xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" '
        'xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" '
        'xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2">');

    // 1. ZATCA UBL Extensions Container (Reserved for UBL Digital Signature block)
    buffer.writeln('  <ext:UBLExtensions>');
    buffer.writeln('    <ext:UBLExtension>');
    buffer.writeln('      <ext:ExtensionURI>urn:oasis:names:specification:ubl:dsig:enveloped:xades</ext:ExtensionURI>');
    buffer.writeln('      <ext:ExtensionContent>');
    buffer.writeln('        <!-- ZATCA Phase 2 Digital Signature Envelope Placeholder -->');
    buffer.writeln('      </ext:ExtensionContent>');
    buffer.writeln('    </ext:UBLExtension>');
    buffer.writeln('  </ext:UBLExtensions>');

    // 2. Core Invoice Metadata
    buffer.writeln('  <cbc:ProfileID>$profileId</cbc:ProfileID>');
    buffer.writeln('  <cbc:ID>${invoice.invoiceNumber}</cbc:ID>');
    buffer.writeln('  <cbc:UUID>$uuid</cbc:UUID>');
    buffer.writeln('  <cbc:IssueDate>$issueDate</cbc:IssueDate>');
    buffer.writeln('  <cbc:IssueTime>$issueTime</cbc:IssueTime>');
    buffer.writeln('  <cbc:InvoiceTypeCode name="$invoiceSubtypeCode">$invoiceTypeCode</cbc:InvoiceTypeCode>');
    buffer.writeln('  <cbc:DocumentCurrencyCode>SAR</cbc:DocumentCurrencyCode>');
    buffer.writeln('  <cbc:TaxCurrencyCode>SAR</cbc:TaxCurrencyCode>');

    // 3. Additional Document References (ICV & PIH)
    // Invoice Counter Value (ICV)
    buffer.writeln('  <cac:AdditionalDocumentReference>');
    buffer.writeln('    <cbc:ID>ICV</cbc:ID>');
    buffer.writeln('    <cbc:UUID>$invoiceCounterValue</cbc:UUID>');
    buffer.writeln('  </cac:AdditionalDocumentReference>');

    // Previous Invoice Hash (PIH) - Chain of Trust
    buffer.writeln('  <cac:AdditionalDocumentReference>');
    buffer.writeln('    <cbc:ID>PIH</cbc:ID>');
    buffer.writeln('    <cac:Attachment>');
    buffer.writeln('      <cbc:EmbeddedDocumentBinaryObject mimeCode="text/plain">$previousInvoiceHash</cbc:EmbeddedDocumentBinaryObject>');
    buffer.writeln('    </cac:Attachment>');
    buffer.writeln('  </cac:AdditionalDocumentReference>');

    // QR Code Placeholder
    if (invoice.zatcaQrBase64 != null) {
      buffer.writeln('  <cac:AdditionalDocumentReference>');
      buffer.writeln('    <cbc:ID>QR</cbc:ID>');
      buffer.writeln('    <cac:Attachment>');
      buffer.writeln('      <cbc:EmbeddedDocumentBinaryObject mimeCode="text/plain">${invoice.zatcaQrBase64}</cbc:EmbeddedDocumentBinaryObject>');
      buffer.writeln('    </cac:Attachment>');
      buffer.writeln('  </cac:AdditionalDocumentReference>');
    }

    // 4. Accounting Supplier Party (الطرف المورد / البائع)
    buffer.writeln('  <cac:AccountingSupplierParty>');
    buffer.writeln('    <cac:Party>');
    buffer.writeln('      <cac:PartyIdentification>');
    buffer.writeln('        <cbc:ID schemeID="CRN">$sellerCrNumber</cbc:ID>');
    buffer.writeln('      </cac:PartyIdentification>');
    buffer.writeln('      <cac:PostalAddress>');
    buffer.writeln('        <cbc:StreetName>$streetName</cbc:StreetName>');
    buffer.writeln('        <cbc:BuildingNumber>$buildingNumber</cbc:BuildingNumber>');
    buffer.writeln('        <cbc:CitySubdivisionName>$districtName</cbc:CitySubdivisionName>');
    buffer.writeln('        <cbc:CityName>$cityName</cbc:CityName>');
    buffer.writeln('        <cbc:PostalZone>$postalCode</cbc:PostalZone>');
    buffer.writeln('        <cac:Country>');
    buffer.writeln('          <cbc:IdentificationCode>SA</cbc:IdentificationCode>');
    buffer.writeln('        </cac:Country>');
    buffer.writeln('      </cac:PostalAddress>');
    buffer.writeln('      <cac:PartyTaxScheme>');
    buffer.writeln('        <cbc:CompanyID>$sellerVatNumber</cbc:CompanyID>');
    buffer.writeln('        <cac:TaxScheme>');
    buffer.writeln('          <cbc:ID>VAT</cbc:ID>');
    buffer.writeln('        </cac:TaxScheme>');
    buffer.writeln('      </cac:PartyTaxScheme>');
    buffer.writeln('      <cac:PartyLegalEntity>');
    buffer.writeln('        <cbc:RegistrationName>$sellerNameAr</cbc:RegistrationName>');
    buffer.writeln('      </cac:PartyLegalEntity>');
    buffer.writeln('    </cac:Party>');
    buffer.writeln('  </cac:AccountingSupplierParty>');

    // 5. Accounting Customer Party (الطرف المشتري / العميل)
    buffer.writeln('  <cac:AccountingCustomerParty>');
    buffer.writeln('    <cac:Party>');
    if (isB2B && invoice.customerVatNumber != null) {
      buffer.writeln('      <cac:PartyTaxScheme>');
      buffer.writeln('        <cbc:CompanyID>${invoice.customerVatNumber}</cbc:CompanyID>');
      buffer.writeln('        <cac:TaxScheme>');
      buffer.writeln('          <cbc:ID>VAT</cbc:ID>');
      buffer.writeln('        </cac:TaxScheme>');
      buffer.writeln('      </cac:PartyTaxScheme>');
    }
    buffer.writeln('      <cac:PartyLegalEntity>');
    buffer.writeln('        <cbc:RegistrationName>${invoice.customerNameAr}</cbc:RegistrationName>');
    buffer.writeln('      </cac:PartyLegalEntity>');
    buffer.writeln('    </cac:Party>');
    buffer.writeln('  </cac:AccountingCustomerParty>');

    // 6. Payment Means (طريقة الدفع)
    final paymentMeansCode = invoice.paymentMethod == PaymentMethod.cash
        ? '10' // Cash
        : (invoice.paymentMethod == PaymentMethod.madaCard
            ? '48' // Bank Card
            : (invoice.paymentMethod == PaymentMethod.bankTransfer ? '42' : '30'));
    buffer.writeln('  <cac:PaymentMeans>');
    buffer.writeln('    <cbc:PaymentMeansCode>$paymentMeansCode</cbc:PaymentMeansCode>');
    buffer.writeln('  </cac:PaymentMeans>');

    // 7. Tax Total (إجمالي ضريبة القيمة المضافة)
    final subtotalStr = invoice.subtotal.toStringAsFixed(2);
    final vatTotalStr = invoice.totalVat.toStringAsFixed(2);
    final grandTotalStr = invoice.grandTotal.toStringAsFixed(2);

    buffer.writeln('  <cac:TaxTotal>');
    buffer.writeln('    <cbc:TaxAmount currencyID="SAR">$vatTotalStr</cbc:TaxAmount>');
    buffer.writeln('    <cac:TaxSubtotal>');
    buffer.writeln('      <cbc:TaxableAmount currencyID="SAR">$subtotalStr</cbc:TaxableAmount>');
    buffer.writeln('      <cbc:TaxAmount currencyID="SAR">$vatTotalStr</cbc:TaxAmount>');
    buffer.writeln('      <cac:TaxCategory>');
    buffer.writeln('        <cbc:ID>S</cbc:ID>'); // S = Standard 15% rate
    buffer.writeln('        <cbc:Percent>15.00</cbc:Percent>');
    buffer.writeln('        <cac:TaxScheme>');
    buffer.writeln('          <cbc:ID>VAT</cbc:ID>');
    buffer.writeln('        </cac:TaxScheme>');
    buffer.writeln('      </cac:TaxCategory>');
    buffer.writeln('    </cac:TaxSubtotal>');
    buffer.writeln('  </cac:TaxTotal>');

    // 8. Legal Monetary Total (الإجماليات النقدية القانونية)
    buffer.writeln('  <cac:LegalMonetaryTotal>');
    buffer.writeln('    <cbc:LineExtensionAmount currencyID="SAR">$subtotalStr</cbc:LineExtensionAmount>');
    buffer.writeln('    <cbc:TaxExclusiveAmount currencyID="SAR">$subtotalStr</cbc:TaxExclusiveAmount>');
    buffer.writeln('    <cbc:TaxInclusiveAmount currencyID="SAR">$grandTotalStr</cbc:TaxInclusiveAmount>');
    buffer.writeln('    <cbc:AllowanceTotalAmount currencyID="SAR">${invoice.discountTotal.toStringAsFixed(2)}</cbc:AllowanceTotalAmount>');
    buffer.writeln('    <cbc:PayableAmount currencyID="SAR">$grandTotalStr</cbc:PayableAmount>');
    buffer.writeln('  </cac:LegalMonetaryTotal>');

    // 9. Invoice Lines (بنود الفاتورة)
    for (int i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final lineSubtotal = item.lineSubtotal.toStringAsFixed(2);
      final lineVat = item.lineVatAmount.toStringAsFixed(2);

      buffer.writeln('  <cac:InvoiceLine>');
      buffer.writeln('    <cbc:ID>${i + 1}</cbc:ID>');
      buffer.writeln('    <cbc:InvoicedQuantity unitCode="PCE">${item.quantity.toInt()}</cbc:InvoicedQuantity>');
      buffer.writeln('    <cbc:LineExtensionAmount currencyID="SAR">$lineSubtotal</cbc:LineExtensionAmount>');
      buffer.writeln('    <cac:TaxTotal>');
      buffer.writeln('      <cbc:TaxAmount currencyID="SAR">$lineVat</cbc:TaxAmount>');
      buffer.writeln('      <cbc:RoundingAmount currencyID="SAR">${item.lineTotalWithVat.toStringAsFixed(2)}</cbc:RoundingAmount>');
      buffer.writeln('    </cac:TaxTotal>');
      buffer.writeln('    <cac:Item>');
      buffer.writeln('      <cbc:Name>${item.productNameAr}</cbc:Name>');
      buffer.writeln('      <cac:ClassifiedTaxCategory>');
      buffer.writeln('        <cbc:ID>S</cbc:ID>');
      buffer.writeln('        <cbc:Percent>15.00</cbc:Percent>');
      buffer.writeln('        <cac:TaxScheme>');
      buffer.writeln('          <cbc:ID>VAT</cbc:ID>');
      buffer.writeln('        </cac:TaxScheme>');
      buffer.writeln('      </cac:ClassifiedTaxCategory>');
      buffer.writeln('    </cac:Item>');
      buffer.writeln('    <cac:Price>');
      buffer.writeln('      <cbc:PriceAmount currencyID="SAR">${item.unitPrice.toStringAsFixed(2)}</cbc:PriceAmount>');
      buffer.writeln('    </cac:Price>');
      buffer.writeln('  </cac:InvoiceLine>');
    }

    buffer.writeln('</Invoice>');
    return buffer.toString();
  }
}

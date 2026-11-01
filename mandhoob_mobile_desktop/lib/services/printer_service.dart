import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../core/utils/esc_pos_generator.dart';

enum PrinterType {
  bluetooth,
  wifi,
  usb,
  sunmiBuiltIn,
}

class ThermalPrinterDevice {
  final String id;
  final String name;
  final String address;
  final PrinterType type;
  final bool isConnected;

  ThermalPrinterDevice({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    this.isConnected = false,
  });
}

class PrinterService extends ChangeNotifier {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal() {
    _availablePrinters.addAll([
      ThermalPrinterDevice(
        id: 'PRN-01',
        name: 'Sunmi V2s Built-in Printer',
        address: 'INTERNAL',
        type: PrinterType.sunmiBuiltIn,
        isConnected: true,
      ),
      ThermalPrinterDevice(
        id: 'PRN-02',
        name: 'Rongta RPP-300 (80mm Bluetooth)',
        address: '66:32:B1:89:12:44',
        type: PrinterType.bluetooth,
      ),
      ThermalPrinterDevice(
        id: 'PRN-03',
        name: 'Zebra ZQ520 (Van Mount)',
        address: '00:15:71:2B:99:10',
        type: PrinterType.bluetooth,
      ),
    ]);
  }

  final List<ThermalPrinterDevice> _availablePrinters = [];
  String _selectedPrinterId = 'PRN-01';
  bool _is80mm = true; // 80mm standard or 58mm portable
  int _copies = 1;

  List<ThermalPrinterDevice> get availablePrinters => List.unmodifiable(_availablePrinters);
  String get selectedPrinterId => _selectedPrinterId;
  bool get is80mm => _is80mm;
  int get copies => _copies;

  ThermalPrinterDevice? get currentPrinter {
    try {
      return _availablePrinters.firstWhere((p) => p.id == _selectedPrinterId);
    } catch (_) {
      return null;
    }
  }

  void selectPrinter(String printerId) {
    _selectedPrinterId = printerId;
    notifyListeners();
  }

  void setPaperWidth(bool is80) {
    _is80mm = is80;
    notifyListeners();
  }

  void setCopies(int num) {
    _copies = num;
    notifyListeners();
  }

  /// Print an invoice via thermal ESC/POS protocol
  Future<bool> printInvoiceThermal(InvoiceModel invoice) async {
    // Generate ESC/POS raw bytes
    final receiptItems = invoice.items
        .map((item) => ReceiptItem(
              name: item.productNameAr,
              qty: item.quantity,
              price: item.unitPrice,
            ))
        .toList();

    final _ = EscPosGenerator.buildVanSalesReceipt(
      companyName: 'شركة المندوب للتوزيع - Mandhoob Co.',
      vatNumber: '310123456700003',
      crNumber: '1010892341',
      invoiceNumber: invoice.invoiceNumber,
      date: invoice.invoiceDate,
      salesmanName: invoice.salesmanName,
      vanId: invoice.warehouseId,
      customerName: invoice.customerNameAr,
      customerVat: invoice.customerVatNumber,
      items: receiptItems,
      subtotal: invoice.subtotal,
      vatTotal: invoice.totalVat,
      discount: invoice.discountTotal,
      grandTotal: invoice.grandTotal,
      paymentMode: invoice.paymentMethod.name,
      qrBase64: invoice.zatcaQrBase64 ?? '',
      is80mm: _is80mm,
    );

    // In a physical environment, write to Bluetooth/TCP socket
    await Future.delayed(const Duration(milliseconds: 600));
    return true;
  }
}

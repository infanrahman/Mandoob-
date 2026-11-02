import 'package:flutter/material.dart';

class AppLanguage extends ChangeNotifier {
  static final AppLanguage _instance = AppLanguage._internal();
  factory AppLanguage() => _instance;
  AppLanguage._internal();

  Locale _locale = const Locale('en'); // Default to English

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';
  TextDirection get textDirection => isArabic ? TextDirection.rtl : TextDirection.ltr;

  static String tr(String key) => _instance.translate(key);

  void toggleLanguage() {
    _locale = _locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    notifyListeners();
  }

  void setLocale(Locale loc) {
    if (_locale != loc) {
      _locale = loc;
      notifyListeners();
    }
  }

  String translate(String key) {
    if (_locale.languageCode == 'ar') {
      return _arabicTranslations[key] ?? key;
    }
    return _englishTranslations[key] ?? key;
  }

  static final Map<String, String> _arabicTranslations = {
    // App
    'app_name': 'مندوب - نظام المبيعات والتوزيع',
    'tagline': 'نظام الفوترة والمبيعات الميدانية المتوافق مع هيئة الزكاة',

    // Nav
    'dashboard': 'الرئيسية',
    'sales': 'المبيعات والفوترة',
    'purchases': 'المشتريات وتوريد المخزون',
    'inventory': 'المخزون وسيارات التوزيع',
    'customers': 'العملاء والذمم',
    'suppliers': 'الموردين والذمم الدائنة',
    'expenses': 'المصروفات والعهدة',
    'reports': 'التقارير والإقرار الضريبي',
    'settings': 'الإعدادات والربط',
    // Mobile Nav
    'nav_home': 'الرئيسية',
    'nav_sales': 'المبيعات',
    'nav_inventory': 'المخزون',
    'nav_customers': 'العملاء',
    'nav_more': 'المزيد',

    // Dashboard
    'today_sales': 'مبيعات اليوم',
    'cash_in_hand': 'نقد الصندوق / العهدة',
    'you_will_get': 'مستحقات لك (عملاء)',
    'you_will_give': 'مستحقات عليك (موردين)',
    'van_stock_value': 'قيمة بضاعة السيارة',
    'quick_actions': 'إجراءات سريعة',
    'new_sale': 'فاتورة بيع',
    'new_van_order': 'بيع سيارة / فوري',
    'payment_in': 'سند قبض',
    'payment_out': 'سند صرف',
    'recent_transactions': 'أحدث المعاملات',
    'low_stock_alert': 'تنبيه نقص المخزون',
    'van_operations_hub': 'غرفة عمليات المناديب',

    // Sales
    'tax_invoice': 'فاتورة ضريبية (B2B)',
    'simplified_tax_invoice': 'فاتورة ضريبية مبسطة (مبيعات سيارة)',
    'quotation': 'عرض أسعار',
    'sales_return': 'مرتجع مبيعات (إشعار دائن)',
    'delivery_challan': 'سند تسليم بضاعة',
    'invoice_number': 'رقم الفاتورة',
    'invoice_date': 'تاريخ الفاتورة',
    'customer': 'العميل',
    'select_customer': 'اختر العميل',
    'add_item': 'إضافة صنف',
    'item_name': 'اسم الصنف',
    'quantity': 'الكمية',
    'unit': 'الوحدة',
    'price': 'السعر',
    'subtotal': 'المجموع قبل الضريبة',
    'discount': 'الخصم',
    'vat_15': 'ضريبة القيمة المضافة (15%)',
    'grand_total': 'الإجمالي النهائي',
    'payment_method': 'طريقة الدفع',
    'cash': 'نقداً',
    'mada': 'مدى / بطاقة',
    'bank_transfer': 'تحويل بنكي',
    'credit': 'آجل (على الحساب)',
    'print_receipt': 'طباعة إيصال حراري',
    'share_pdf': 'مشاركة PDF',
    'zatca_qr': 'رمز التحقق لهيئة الزكاة (QR)',

    // Inventory
    'stock_inventory': 'إدارة المخزون والسيارات',
    'warehouse': 'المستودع',
    'main_warehouse': 'المستودع الرئيسي',
    'van': 'سيارة التوزيع',
    'stock_transfer': 'نقل مخزني إلى السيارة',
    'batch_number': 'رقم التشغيلة / الدفعة',
    'expiry_date': 'تاريخ الانتهاء',
    'current_stock': 'الرصيد الحالي',
    'add_product': 'إضافة صنف جديد',

    // Reports
    'zatca_report': 'تقرير الإقرار الضريبي (ZATCA)',
    'day_book': 'دفتر اليومية',
    'profit_loss': 'تقرير الأرباح والخسائر',
    'stock_summary': 'ملخص حركة المخزون',
    'salesman_report': 'تقرير أداء المندوبين',

    // Settings
    'company_profile': 'الملف التعريفي للمنشأة',
    'vat_number': 'الرقم الضريبي',
    'cr_number': 'رقم السجل التجاري',
    'zatca_setup': 'ربط هيئة الزكاة والضريبة (الفاتورة الإلكترونية)',
    'printer_setup': 'إعدادات الطابعة الحرارية (Bluetooth / Wi-Fi)',
    'user_management': 'إدارة المستخدمين والصلاحيات',
    'sync_cloud': 'مزامنة السحابة والوضع غير المتصل',
    'language': 'اللغة / Language',
  };

  static final Map<String, String> _englishTranslations = {
    // App
    'app_name': 'M-Andhoob - Sales & Van Distribution',
    'tagline': 'ZATCA-Compliant Mobile & Van Sales ERP',

    // Nav
    'dashboard': 'Dashboard',
    'sales': 'Sales & Invoicing',
    'purchases': 'Purchases & Inward Stock',
    'inventory': 'Stock & Van Inventory',
    'customers': 'Customers & Receivables',
    'suppliers': 'Suppliers & Payables',
    'expenses': 'Expenses & Float',
    'reports': 'Reports & Tax Returns',
    'settings': 'Settings & Setup',
    // Mobile Nav
    'nav_home': 'Home',
    'nav_sales': 'Sales',
    'nav_inventory': 'Stock',
    'nav_customers': 'Clients',
    'nav_more': 'More',

    // Dashboard
    'today_sales': "Today's Sales",
    'cash_in_hand': 'Cash Float in Hand',
    'you_will_get': "You'll Get (Receivables)",
    'you_will_give': "You'll Give (Payables)",
    'van_stock_value': 'Van Stock Value',
    'quick_actions': 'Quick Actions',
    'new_sale': 'New Sale',
    'new_van_order': 'Van Spot Sale',
    'payment_in': 'Payment In',
    'payment_out': 'Payment Out',
    'recent_transactions': 'Recent Transactions',
    'low_stock_alert': 'Low Stock Alert',
    'van_operations_hub': 'Van Operations Hub',

    // Sales
    'tax_invoice': 'Tax Invoice (B2B)',
    'simplified_tax_invoice': 'Simplified Tax Invoice (Van Sale)',
    'quotation': 'Quotation / Estimate',
    'sales_return': 'Sales Return (Credit Note)',
    'delivery_challan': 'Delivery Challan',
    'invoice_number': 'Invoice #',
    'invoice_date': 'Invoice Date',
    'customer': 'Customer',
    'select_customer': 'Select Customer',
    'add_item': 'Add Item',
    'item_name': 'Item Name',
    'quantity': 'Quantity',
    'unit': 'Unit',
    'price': 'Price',
    'subtotal': 'Subtotal (Excl. VAT)',
    'discount': 'Discount',
    'vat_15': 'VAT (15%)',
    'grand_total': 'Grand Total',
    'payment_method': 'Payment Mode',
    'cash': 'Cash',
    'mada': 'Mada / Card',
    'bank_transfer': 'Bank Transfer',
    'credit': 'Credit / On Account',
    'print_receipt': 'Print Thermal Receipt',
    'share_pdf': 'Share PDF',
    'zatca_qr': 'ZATCA Verification QR',

    // Inventory
    'stock_inventory': 'Stock & Van Inventory',
    'warehouse': 'Warehouse',
    'main_warehouse': 'Main Warehouse',
    'van': 'Sales Van',
    'stock_transfer': 'Stock Transfer to Van',
    'batch_number': 'Batch Number',
    'expiry_date': 'Expiry Date',
    'current_stock': 'Current Stock',
    'add_product': 'Add New Product',

    // Reports
    'zatca_report': 'ZATCA VAT Return Report',
    'day_book': 'Day Book',
    'profit_loss': 'Profit & Loss',
    'stock_summary': 'Stock Summary',
    'salesman_report': 'Salesman Performance',

    // Settings
    'company_profile': 'Company Profile',
    'vat_number': 'VAT Registration No.',
    'cr_number': 'CR Number',
    'zatca_setup': 'ZATCA Integration Setup',
    'printer_setup': 'Thermal Printer Setup (Bluetooth/Wi-Fi)',
    'user_management': 'User Management & Roles',
    'sync_cloud': 'Cloud Sync & Offline Status',
    'language': 'Language / اللغة',
  };
}

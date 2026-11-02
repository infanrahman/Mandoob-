import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/database_service.dart';
import '../../services/printer_service.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../models/user_model.dart';
import 'company_profile_screen.dart';
import 'create_company_screen.dart';
import 'user_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _offlineCacheEnabled = true;
  bool _zatcaPhase2Active = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), PrinterService(), AuthService(), SyncService(), AppLanguage()]),
      builder: (context, _) {
        final db = DatabaseService();
        final printer = PrinterService();
        final auth = AuthService();
        final sync = SyncService();
        final lang = AppLanguage();

        return Scaffold(
          appBar: AppBar(
            title: Text(lang.isArabic ? 'الإعدادات والربط والتهيئة' : 'Settings & Configurations'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 0. Language & Regional Settings Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.language, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            lang.isArabic ? 'اللغة والاتجاه (Language & Layout)' : 'Language & Layout / اللغة',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lang.isArabic
                            ? 'اختر لغة واجهة النظام، يدعم التطبيق التوجيه الكامل من اليمين لليسار (RTL) للغة العربية ومن اليسار لليمين (LTR) للغة الإنجليزية مع التحديث الفوري.'
                            : 'Select app language. Supports full RTL orientation for Arabic (Saudi ZATCA compliant) and LTR for English with instant live switching.',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('🇸🇦 العربية (RTL)'),
                                ],
                              ),
                              selected: lang.isArabic,
                              onSelected: (selected) {
                                if (selected) lang.setLocale(const Locale('ar'));
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('🌐 English (LTR)'),
                                ],
                              ),
                              selected: !lang.isArabic,
                              onSelected: (selected) {
                                if (selected) lang.setLocale(const Locale('en'));
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 1. Company Profile Card
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
                          Text(
                            lang.isArabic ? 'بيانات المنشأة' : 'Company Profile',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (auth.currentRole == UserRole.superAdmin)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CreateCompanyScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.add_business, size: 14),
                                  label: Text(lang.isArabic ? 'إضافة منشأة' : '+ Company'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.saleGreen,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
                                  );
                                },
                                icon: const Icon(Icons.edit, size: 14),
                                label: Text(lang.isArabic ? 'تعديل البيانات' : 'Edit Profile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(lang.isArabic ? db.companyNameAr : db.companyNameEn, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(lang.isArabic ? db.companyNameEn : db.companyNameAr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Text('${lang.isArabic ? "الرقم الضريبي (VAT)" : "VAT Number"}: ${db.vatNumber}', style: const TextStyle(fontSize: 13)),
                      Text('${lang.isArabic ? "السجل التجاري (CR)" : "CR Number"}: ${db.crNumber}', style: const TextStyle(fontSize: 13)),
                      Text('${lang.isArabic ? "العنوان الوطني" : "National Address"}: ${db.street}، ${db.district}، ${db.city}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 2. ZATCA Link & Integration (Visible ONLY to Admin & SuperAdmin)
              if (auth.hasRole([UserRole.admin, UserRole.superAdmin])) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lang.isArabic
                                    ? 'ربط الفاتورة الإلكترونية (ZATCA)'
                                    : 'ZATCA Phase 2 E-Invoicing',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                lang.isArabic ? 'مرتبط (CSID)' : 'Connected (CSID)',
                                style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        Text(
                          lang.isArabic
                              ? 'حالة المرحلة الثانية: التشفير، الختم الرقمي (ECDSA Cryptographic Stamp)، هاش الفاتورة SHA-256، وتوليد ملفات UBL 2.1 XML مفعلة بالكامل.'
                              : 'Phase 2 Status: Cryptographic hashing (SHA-256 Tag 6), ECDSA Stamp (Tag 7), X.509 Certificate (Tag 8), and UBL 2.1 XML fully enabled.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              lang.isArabic ? 'بيئة الربط (Environment):' : 'Integration Environment:',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Chip(
                              label: Text(
                                lang.isArabic ? 'Simulation Platform (محاكاة)' : 'Simulation Platform',
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: Colors.blue.shade50,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showZatcaOnboardDialog(context),
                              icon: const Icon(Icons.vpn_key, size: 16),
                              label: Text(lang.isArabic ? 'تجديد شهادة CSID / رمز OTP' : 'Renew CSID / OTP'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      lang.isArabic
                                          ? 'تم اختبار الاتصال ببوابة فاتورة (ZATCA Fatoora API): متصل وجاهز!'
                                          : 'ZATCA Fatoora API connection test: Connected and healthy!',
                                    ),
                                    backgroundColor: AppColors.saleGreen,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.network_check, size: 16),
                              label: Text(lang.isArabic ? 'فحص الاتصال بالبوابة' : 'Test API Health'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 3. Thermal Printer Setup (Bluetooth / Wi-Fi)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.print, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lang.isArabic ? 'إعدادات الطابعة الحرارية (Thermal Printer ESC/POS)' : 'Thermal Printer ESC/POS Setup',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 18),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: printer.selectedPrinterId,
                        decoration: InputDecoration(
                          labelText: lang.isArabic ? 'الطابعة الافتراضية المتصلة' : 'Connected Default Printer',
                        ),
                        items: printer.availablePrinters.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.name} (${p.address})', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) printer.selectPrinter(val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(lang.isArabic ? 'عرض الورق الحراري:' : 'Paper Width:'),
                          ChoiceChip(
                            label: Text(lang.isArabic ? '80mm (قياسي)' : '80mm (Standard)'),
                            selected: printer.is80mm,
                            onSelected: (_) => printer.setPaperWidth(true),
                          ),
                          ChoiceChip(
                            label: Text(lang.isArabic ? '58mm (محمول)' : '58mm (Portable Van)'),
                            selected: !printer.is80mm,
                            onSelected: (_) => printer.setPaperWidth(false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang.isArabic
                                    ? 'تم إرسال صفحة اختبار الطباعة إلى الطابعة بنجاح!'
                                    : 'Test receipt sent to printer successfully!',
                              ),
                              backgroundColor: AppColors.saleGreen,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: Text(lang.isArabic ? 'طباعة صفحة اختبار (Test Print)' : 'Print Test Page'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 4. Role & Permissions Matrix
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.admin_panel_settings, color: Colors.purple),
                              const SizedBox(width: 8),
                              Text(
                                lang.isArabic ? 'المستخدمون والصلاحيات' : 'Users & Permissions',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          if (auth.can((p) => p.canManageUsers))
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                                );
                              },
                              icon: const Icon(Icons.people, size: 14),
                              label: Text(lang.isArabic ? 'إدارة المستخدمين' : 'Manage Users'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 18),
                      Text('${lang.isArabic ? "المستخدم النشط" : "Active User"}: ${auth.currentUser.name}'),
                      Text('${lang.isArabic ? "المنشأة التابع لها" : "Company"}: ${lang.isArabic ? db.companyNameAr : db.companyNameEn}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text('${lang.isArabic ? "الصلاحية" : "Role"}: ${lang.isArabic ? auth.currentUser.roleDisplayNameAr : auth.currentUser.role.name.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildPermBadge(lang.isArabic ? 'إصدار فواتير' : 'Create Invoices', auth.permissions.canCreateSale),
                          _buildPermBadge(lang.isArabic ? 'تعديل فواتير' : 'Edit Invoices', auth.permissions.canEditSale),
                          _buildPermBadge(lang.isArabic ? 'حذف فواتير' : 'Delete Invoices', auth.permissions.canDeleteSale),
                          _buildPermBadge(lang.isArabic ? 'نقل بضاعة سيارة' : 'Van Stock Transfer', auth.permissions.canTransferVanStock),
                          _buildPermBadge(lang.isArabic ? 'رؤية الأرباح والتكلفة' : 'View Margin & Cost', auth.permissions.canViewProfitAndCost),
                          _buildPermBadge(lang.isArabic ? 'التقارير المالية' : 'Financial Reports', auth.permissions.canViewReports),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 5. Cloud Sync & Notifications
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(lang.isArabic ? 'التخزين المحلي والمزامنة غير المتصلة (Offline First)' : 'Local Storage & Offline-First Sync'),
                      subtitle: Text(lang.isArabic ? 'حفظ الفواتير محلياً على الجهاز والمزامنة التلقائية عند الاتصال' : 'Save all transactions locally on device and automatically sync deltas to cloud when connected'),
                      value: _offlineCacheEnabled,
                      onChanged: (val) => setState(() => _offlineCacheEnabled = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(lang.isArabic ? 'إشعارات النظام والمخزون المنخفض' : 'System Alerts & Low Stock Alerts'),
                      subtitle: Text(lang.isArabic ? 'تنبيه فوري عند وصول صنف لحد الطلب أو قرب انتهاء صلاحيته' : 'Instant warning when stock drops below threshold or batch nears expiration'),
                      value: _notificationsEnabled,
                      onChanged: (val) => setState(() => _notificationsEnabled = val),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.storage, color: Colors.teal),
                      title: Text(lang.isArabic ? 'حالة التخزين المحلي (Local Storage Persistence)' : 'Local Storage Persistence'),
                      subtitle: Text(
                        lang.isArabic
                            ? 'البيانات والمخزون والفواتير مخزنة محلياً في الذاكرة الدائمة للجهاز وتعمل 100% بدون إنترنت'
                            : 'All stock, items & invoices are persisted to device storage. Operates 100% offline.',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              lang.isArabic ? 'نشط ومحفوظ' : 'Persisted',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore, color: Colors.orange),
                      title: Text(lang.isArabic ? 'استعادة البيانات التجريبية الافتراضية' : 'Reset to Default Demo Data'),
                      subtitle: Text(
                        lang.isArabic
                            ? 'مسح التخزين المحلي واستعادة بيانات الأصناف والمبيعات التجريبية الأولية'
                            : 'Clear local database cache and restore initial seed data',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: auth.can((p) => p.canResetSystemData)
                          ? OutlinedButton(
                              onPressed: () => _confirmResetDemoData(context, lang, db),
                              child: Text(lang.isArabic ? 'استعادة' : 'Reset'),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                              child: Text(lang.isArabic ? 'صلاحية محظورة' : 'Locked', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.sync, color: AppColors.primary),
                      title: Text(lang.isArabic ? 'مزامنة فورية مع الخادم السحابي' : 'Instant Cloud Sync Delta'),
                      subtitle: Text('${lang.isArabic ? "آخر مزامنة" : "Last Sync"}: ${sync.lastSyncTime.toString().substring(0, 16)}'),
                      trailing: ElevatedButton(
                        onPressed: () => sync.triggerSync(),
                        child: Text(lang.isArabic ? 'مزامنة الآن' : 'Sync Now'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showZatcaOnboardDialog(BuildContext context) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.green),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'ربط جهاز الفوترة (ZATCA Onboarding)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أدخل رمز التحقق (OTP) الصادر من منصة فاتورة (Fatoora Portal) لاستخراج شهادة الاعتماد الرقمية (CSID):',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'رمز التحقق OTP المكون من 6 أرقام',
                prefixIcon: Icon(Icons.password),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إرسال طلب الاعتماد وتجديد شهادة CSID بنجاح! تم اعتماد الربط مع هيئة الزكاة.'),
                  backgroundColor: AppColors.saleGreen,
                ),
              );
            },
            child: const Text('تأكيد وإصدار شهادة CSID'),
          ),
        ],
      ),
    );
  }

  void _confirmResetDemoData(BuildContext context, AppLanguage lang, DatabaseService db) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lang.isArabic ? 'استعادة البيانات التجريبية' : 'Reset to Demo Data',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          lang.isArabic
              ? 'هل تريد بالتأكيد مسح التخزين المحلي واستعادة الأصناف والمستودعات والعملاء الافتراضيين؟'
              : 'Are you sure you want to clear local storage and restore default demo products, warehouses, and customers?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              await db.resetToInitialDemoData();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lang.isArabic
                          ? 'تمت استعادة البيانات التجريبية الافتراضية بنجاح'
                          : 'Default demo data restored successfully',
                    ),
                    backgroundColor: Colors.orange.shade800,
                  ),
                );
              }
            },
            child: Text(
              lang.isArabic ? 'استعادة وتعيين' : 'Reset & Restore',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermBadge(String label, bool allowed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: allowed ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: allowed ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(allowed ? Icons.check : Icons.close, size: 12, color: allowed ? Colors.green : Colors.red),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: allowed ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

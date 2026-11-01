import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/company_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class CreateCompanyScreen extends StatefulWidget {
  final bool isInitialSetup;

  const CreateCompanyScreen({super.key, this.isInitialSetup = false});

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _vatController = TextEditingController();
  final _crController = TextEditingController();
  final _buildingController = TextEditingController();
  final _streetController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController(text: 'الرياض - Riyadh');
  final _postalController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bankController = TextEditingController(text: 'مصرف الراجحي - Al Rajhi Bank');
  final _ibanController = TextEditingController();

  // If initial setup, also collect Super Admin credentials
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _vatController.dispose();
    _crController.dispose();
    _buildingController.dispose();
    _streetController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bankController.dispose();
    _ibanController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPhoneController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isInitialSetup
            ? 'إنشاء منشأة جديدة وحساب Super Admin'
            : 'إضافة منشأة تجارية جديدة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1E40AF)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.add_business, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تسجيل منشأة تجارية جديدة (New Tenant / Company)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isInitialSetup
                                ? 'يتم إنشاء المنشأة وتعيين منشئها كـ Super Admin'
                                : 'فقط الـ Super Admin يملك صلاحية إنشاء منشآت وربطها بهيئة الزكاة',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Super Admin Section (Shown if Initial Setup)
              if (widget.isInitialSetup) ...[
                const Text(
                  '1. بيانات مالك المنشأة (Super Admin Credentials)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _adminNameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم مالك المنشأة (Super Admin) *',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _adminPhoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'رقم الجوال *',
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _adminEmailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'البريد الإلكتروني *',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _adminPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'كلمة مرور المشرف العام *',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          validator: (v) => v != null && v.length < 6 ? '6 أحرف على الأقل' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Company Legal Details
              Text(
                widget.isInitialSetup ? '2. بيانات المنشأة القانونية (Legal Business Details)' : 'بيانات المنشأة القانونية',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameArController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المنشأة بالعربية (مثل: شركة الرائد للتوزيع) *',
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال اسم المنشأة' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nameEnController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المنشأة بالإنجليزية (English Business Name) *',
                          prefixIcon: Icon(Icons.language),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال الاسم بالإنجليزية' : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _vatController,
                              keyboardType: TextInputType.number,
                              maxLength: 15,
                              decoration: const InputDecoration(
                                labelText: 'الرقم الضريبي ZATCA (15 رقم) *',
                                prefixIcon: Icon(Icons.verified),
                              ),
                              validator: (v) {
                                if (v == null || v.length != 15) return '15 رقماً إلزامياً';
                                if (!v.startsWith('3') || !v.endsWith('3')) return 'يبدأ وينتهي بـ 3';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _crController,
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              decoration: const InputDecoration(
                                labelText: 'السجل التجاري CR *',
                                prefixIcon: Icon(Icons.badge),
                              ),
                              validator: (v) => v == null || v.length != 10 ? '10 أرقام' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Saudi National Address
              const Text(
                'العنوان الوطني السعودي (National Address - ZATCA Mandatory)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(labelText: 'المدينة *'),
                              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _districtController,
                              decoration: const InputDecoration(labelText: 'الحي *'),
                              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _streetController,
                        decoration: const InputDecoration(labelText: 'اسم الشارع *'),
                        validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _buildingController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              decoration: const InputDecoration(labelText: 'رقم المبنى (4 أرقام) *'),
                              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _postalController,
                              keyboardType: TextInputType.number,
                              maxLength: 5,
                              decoration: const InputDecoration(labelText: 'الرمز البريدي (5 أرقام) *'),
                              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitCreateCompany,
                  icon: const Icon(Icons.check_circle),
                  label: Text(widget.isInitialSetup
                      ? 'إنشاء المنشأة والبدء كـ Super Admin'
                      : 'حفظ وتفعيل المنشأة الجديدة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saleGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitCreateCompany() {
    if (_formKey.currentState?.validate() ?? false) {
      final db = DatabaseService();
      final auth = AuthService();

      final newCompany = CompanyModel(
        id: 'COMP-${DateTime.now().millisecondsSinceEpoch}',
        nameAr: _nameArController.text.trim(),
        nameEn: _nameEnController.text.trim(),
        vatNumber: _vatController.text.trim(),
        crNumber: _crController.text.trim(),
        buildingNumber: _buildingController.text.trim(),
        street: _streetController.text.trim(),
        district: _districtController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? '0110000000' : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? 'info@company.sa' : _emailController.text.trim(),
        bankName: _bankController.text.trim(),
        iban: _ibanController.text.trim(),
        createdBySuperAdminId: auth.currentUser.id,
        createdAt: DateTime.now(),
      );

      db.addCompany(newCompany);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء المنشأة "${newCompany.nameAr}" بنجاح!'),
          backgroundColor: AppColors.saleGreen,
        ),
      );

      Navigator.pop(context);
    }
  }
}

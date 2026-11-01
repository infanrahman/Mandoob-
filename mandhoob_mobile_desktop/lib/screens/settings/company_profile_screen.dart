import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/database_service.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _vatController;
  late TextEditingController _crController;
  late TextEditingController _buildingController;
  late TextEditingController _streetController;
  late TextEditingController _districtController;
  late TextEditingController _cityController;
  late TextEditingController _postalController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _ibanController;
  late TextEditingController _bankController;

  @override
  void initState() {
    super.initState();
    final db = DatabaseService();
    _nameArController = TextEditingController(text: db.companyNameAr);
    _nameEnController = TextEditingController(text: db.companyNameEn);
    _vatController = TextEditingController(text: db.vatNumber);
    _crController = TextEditingController(text: db.crNumber);
    _buildingController = TextEditingController(text: db.buildingNumber);
    _streetController = TextEditingController(text: db.street);
    _districtController = TextEditingController(text: db.district);
    _cityController = TextEditingController(text: db.city);
    _postalController = TextEditingController(text: db.postalCode);
    _phoneController = TextEditingController(text: '0112345678');
    _emailController = TextEditingController(text: 'info@mandhoob.sa');
    _ibanController = TextEditingController(text: 'SA0380000000608010167519');
    _bankController = TextEditingController(text: 'مصرف الراجحي - Al Rajhi Bank');
  }

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
    _ibanController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف التعريفي للمنشأة / Company Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'حفظ التعديلات',
            onPressed: _saveCompanyProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice banner about ZATCA legal requirements
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'بيانات المنشأة والعنوان الوطني إلزامية للامتثال لمتطلبات هيئة الزكاة (ZATCA Phase 2) وللطباعة على الفواتير والإيصالات الحرارية.',
                        style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 1. Legal Entity Names
              const Text(
                'الاسم التجاري للمنشأة (Legal Business Name)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _nameArController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنشأة باللغة العربية *',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال اسم المنشأة بالعربية' : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _nameEnController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنشأة باللغة الإنجليزية (English Name) *',
                  prefixIcon: Icon(Icons.language),
                ),
                validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال اسم المنشأة بالإنجليزية' : null,
              ),

              const SizedBox(height: 20),

              // 2. Tax & Commercial Registration
              const Text(
                'التراخيص والأرقام الضريبية (ZATCA & Commercial Licenses)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
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
                        labelText: 'الرقم الضريبي (15 رقم) *',
                        prefixIcon: Icon(Icons.verified),
                        helperText: 'يبدأ وينتهي بالرقم 3 (ZATCA VAT)',
                      ),
                      validator: (val) {
                        if (val == null || val.length != 15) return 'يجب أن يتكون من 15 رقم';
                        if (!val.startsWith('3') || !val.endsWith('3')) return 'يجب أن يبدأ وينتهي بالرقم 3';
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
                        labelText: 'السجل التجاري (CR) *',
                        prefixIcon: Icon(Icons.badge),
                        helperText: '10 أرقام من وزارة التجارة',
                      ),
                      validator: (val) => val == null || val.length != 10 ? '10 أرقام' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3. National Address (العنوان الوطني المعتمد)
              const Text(
                'العنوان الوطني السعودي (National Address - ZATCA Mandatory)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'المدينة (City) *'),
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      decoration: const InputDecoration(labelText: 'الحي (District) *'),
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'اسم الشارع (Street Name) *'),
                validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال اسم الشارع' : null,
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _buildingController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'رقم المبنى (4 أرقام) *'),
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _postalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'الرمز البريدي (5 أرقام) *'),
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 4. Banking & Contact Details
              const Text(
                'البيانات البنكية ومعلومات الاتصال (Bank & Contact Info)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _bankController,
                decoration: const InputDecoration(
                  labelText: 'اسم البنك المعتمد للمنشأة',
                  prefixIcon: Icon(Icons.account_balance),
                ),
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _ibanController,
                decoration: const InputDecoration(
                  labelText: 'رقم الآيبان البنكي (IBAN)',
                  prefixIcon: Icon(Icons.credit_card),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'رقم الهاتف / الجوال', prefixIcon: Icon(Icons.phone)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveCompanyProfile,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ وتحديث بيانات المنشأة في النظام'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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

  void _saveCompanyProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      final db = DatabaseService();
      db.updateCompanyProfile(
        nameAr: _nameArController.text.trim(),
        nameEn: _nameEnController.text.trim(),
        vatNumber: _vatController.text.trim(),
        crNumber: _crController.text.trim(),
        buildingNumber: _buildingController.text.trim(),
        street: _streetController.text.trim(),
        district: _districtController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث بيانات المنشأة بنجاح في كافة الفواتير والتقارير ورمز ZATCA!'),
          backgroundColor: AppColors.saleGreen,
        ),
      );

      Navigator.pop(context);
    }
  }
}

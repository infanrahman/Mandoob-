enum UserRole {
  superAdmin,
  admin,
  salesman,
  accountant,
}

class AppPermissions {
  final bool canViewDashboard;
  final bool canCreateSale;
  final bool canEditSale;
  final bool canDeleteSale;
  final bool canCreatePurchase;
  final bool canManageInventory;
  final bool canTransferVanStock;
  final bool canViewProfitAndCost;
  final bool canManageUsers;
  final bool canConfigureZatca;
  final bool canConfigurePrinter;
  final bool canViewReports;

  const AppPermissions({
    required this.canViewDashboard,
    required this.canCreateSale,
    required this.canEditSale,
    required this.canDeleteSale,
    required this.canCreatePurchase,
    required this.canManageInventory,
    required this.canTransferVanStock,
    required this.canViewProfitAndCost,
    required this.canManageUsers,
    required this.canConfigureZatca,
    required this.canConfigurePrinter,
    required this.canViewReports,
  });

  static AppPermissions fromRole(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return const AppPermissions(
          canViewDashboard: true,
          canCreateSale: true,
          canEditSale: true,
          canDeleteSale: true,
          canCreatePurchase: true,
          canManageInventory: true,
          canTransferVanStock: true,
          canViewProfitAndCost: true,
          canManageUsers: true,
          canConfigureZatca: true,
          canConfigurePrinter: true,
          canViewReports: true,
        );
      case UserRole.admin:
        return const AppPermissions(
          canViewDashboard: true,
          canCreateSale: true,
          canEditSale: true,
          canDeleteSale: false,
          canCreatePurchase: true,
          canManageInventory: true,
          canTransferVanStock: true,
          canViewProfitAndCost: true,
          canManageUsers: true,
          canConfigureZatca: true,
          canConfigurePrinter: true,
          canViewReports: true,
        );
      case UserRole.salesman:
        return const AppPermissions(
          canViewDashboard: true, // restricted to own van stats
          canCreateSale: true,
          canEditSale: false,
          canDeleteSale: false,
          canCreatePurchase: false,
          canManageInventory: false,
          canTransferVanStock: true, // Load request
          canViewProfitAndCost: false, // Cannot see profit/cost margins
          canManageUsers: false,
          canConfigureZatca: false,
          canConfigurePrinter: true,
          canViewReports: false,
        );
      case UserRole.accountant:
        return const AppPermissions(
          canViewDashboard: true,
          canCreateSale: true,
          canEditSale: true,
          canDeleteSale: false,
          canCreatePurchase: true,
          canManageInventory: true,
          canTransferVanStock: true,
          canViewProfitAndCost: true,
          canManageUsers: false,
          canConfigureZatca: false,
          canConfigurePrinter: true,
          canViewReports: true,
        );
    }
  }
}

class UserModel {
  final String id;
  final String companyId; // The root company this user belongs to
  final String companyNameAr;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? assignedVanId; // E.g. 'VAN-01' for salesman
  final String? assignedVanName;
  final bool isActive;
  final AppPermissions permissions;

  UserModel({
    required this.id,
    this.companyId = 'COMP-001',
    this.companyNameAr = 'شركة المندوب للتوزيع والتجارة المحدودة',
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.assignedVanId,
    this.assignedVanName,
    this.isActive = true,
    AppPermissions? permissions,
  }) : permissions = permissions ?? AppPermissions.fromRole(role);

  String get roleDisplayNameAr {
    switch (role) {
      case UserRole.superAdmin:
        return 'المدير العام (Super Admin)';
      case UserRole.admin:
        return 'مدير النظام (Admin)';
      case UserRole.salesman:
        return 'مندوب مبيعات (Van Sales)';
      case UserRole.accountant:
        return 'محاسب (Accountant)';
    }
  }

  String get roleDisplayNameEn {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.salesman:
        return 'Van Salesman';
      case UserRole.accountant:
        return 'Accountant';
    }
  }
}

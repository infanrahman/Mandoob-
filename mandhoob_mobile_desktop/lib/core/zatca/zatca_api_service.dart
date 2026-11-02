import 'package:flutter/material.dart';

enum ZatcaEnvironment {
  developerSandbox,
  simulation,
  production,
}

enum ZatcaInvoiceStatus {
  notSubmitted,
  reported, // B2C Simplified Invoices
  cleared, // B2B Standard Tax Invoices
  rejected,
  warning,
}

class ZatcaApiResponse {
  final bool success;
  final ZatcaInvoiceStatus status;
  final String? clearedInvoiceXml;
  final String? warningMessage;
  final String? errorMessage;
  final List<String> validationErrors;

  ZatcaApiResponse({
    required this.success,
    required this.status,
    this.clearedInvoiceXml,
    this.warningMessage,
    this.errorMessage,
    this.validationErrors = const [],
  });
}

class ZatcaApiService extends ChangeNotifier {
  static final ZatcaApiService _instance = ZatcaApiService._internal();
  factory ZatcaApiService() => _instance;
  ZatcaApiService._internal();

  ZatcaEnvironment currentEnvironment = ZatcaEnvironment.simulation;
  bool isOnboarded = true;
  String csidBinaryToken = 'CSID-PROD-2026-SA-998877';
  String csidSecret = 'sec-98124401-zatca-ksa';

  String get baseUrl {
    switch (currentEnvironment) {
      case ZatcaEnvironment.developerSandbox:
        return 'https://gw-fatoora.zatca.gov.sa/e-invoicing/developer-portal';
      case ZatcaEnvironment.simulation:
        return 'https://gw-fatoora.zatca.gov.sa/e-invoicing/simulation';
      case ZatcaEnvironment.production:
        return 'https://gw-fatoora.zatca.gov.sa/e-invoicing/core';
    }
  }

  /// Onboarding: Request Compliance CSID using Fatoora Portal OTP & CSR
  Future<bool> onboardWithOtp({
    required String otp,
    required String csrPem,
  }) async {
    // Simulates ZATCA /compliance API call
    await Future.delayed(const Duration(seconds: 2));
    isOnboarded = true;
    notifyListeners();
    return true;
  }

  /// Clearance API (for B2B Standard Tax Invoices)
  /// Mandatory real-time clearance before issuing to the customer
  Future<ZatcaApiResponse> submitForClearance({
    required String invoiceXml,
    required String invoiceHash,
    required String uuid,
  }) async {
    // In production: POST to $baseUrl/invoices/clearance/single
    await Future.delayed(const Duration(milliseconds: 900));

    return ZatcaApiResponse(
      success: true,
      status: ZatcaInvoiceStatus.cleared,
      clearedInvoiceXml: invoiceXml,
      warningMessage: 'تم اعتماد وختم الفاتورة الضريبية رسمياً من منصة فاتورة (ZATCA Cleared)',
    );
  }

  /// Reporting API (for B2C Simplified Tax Invoices / Van Sales)
  /// Issued immediately on the spot, reported to ZATCA within 24 hours
  Future<ZatcaApiResponse> submitForReporting({
    required String invoiceXml,
    required String invoiceHash,
    required String uuid,
  }) async {
    // In production: POST to $baseUrl/invoices/reporting/single
    await Future.delayed(const Duration(milliseconds: 700));

    return ZatcaApiResponse(
      success: true,
      status: ZatcaInvoiceStatus.reported,
      warningMessage: 'تم إبلاغ هيئة الزكاة بالفاتورة المبسطة بنجاح (ZATCA Reported)',
    );
  }
}

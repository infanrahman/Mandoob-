# M-Andhoob (مندوب) - Enterprise Van Sales & ERP System
### Vyapar-Style Billing, Stock & Distribution Suite for Saudi Arabia (KSA)
#### Fully Compliant with Saudi ZATCA (Fatoora) E-Invoicing Phase 1 & 2

---

## 🌟 Executive Summary

**M-Andhoob (مندوب)** is an offline-first Sales & Van Sales Mobile and Desktop ERP application tailored for the Saudi Arabian market. Designed with the fast, intuitive workflow of **Vyapar App**, it equips sales representatives, van drivers, accountants, and company management with:

1. **Cross-Platform Unified Application (`mandhoob_mobile_desktop`)**:
   - Supports **Android**, **iOS**, **Android Tablets / iPads**, and **Windows / macOS Desktop**.
   - Adaptive UI: Bottom navigation on smartphones, NavigationRail / Master-Detail on tablets & desktops.
2. **Saudi ZATCA E-Invoicing Engine (Phase 1 & Phase 2 Integration)**:
   - **UBL 2.1 XML Standard**: Full OASIS UBL 2.1 syntax generator (`<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2">`) with ProfileID `reporting:1.0` (B2C) & `clearance:1.0` (B2B).
   - **Chain of Trust**: Sequential Invoice Counter Value (ICV) and cryptographic Previous Invoice Hash (PIH).
   - **Invoice Hashing**: Canonicalized SHA-256 XML Digest (Tag 6).
   - **Digital Signature**: ECDSA Cryptographic Stamp (Tag 7) using CSID private keys.
   - **Public Key Certificate**: X.509 Base64 Certificate (Tag 8).
   - **Full 8-Tag TLV Base64 QR Code**: Formatted for both Simplified (Van Sales / B2C) and Standard Tax Invoices (B2B).
   - **Fatoora Portal API Connector**: Clearance (`/invoices/clearance/single`), Reporting (`/invoices/reporting/single`), and Onboarding (`/compliance` CSID).
3. **Van Sales Distribution & Mobile Inventory**:
   - Van-as-a-Warehouse hierarchy (`WH-MAIN` -> `VAN-01`, `VAN-02`).
   - Morning van stock loading and evening reconciliation.
   - Batch numbers, expiry date alerts, and multi-unit conversions (e.g. 1 Carton = 24 Pieces).
4. **Credit Tracking & Aging Analysis (الذمم والمستحقات وأعمار الديون)**:
   - **For Customers**: Credit Limit (سقف الائتمان), Credit Period in days, Available Credit Remaining, Real-time Credit Limit Violation Guard during invoicing, Payment In vouchers (سندات قبض نقد/مدى/تحويل) deducting customer balances, and WhatsApp collection reminders.
   - **For Suppliers**: Credit Limit, Credit Days, Current Payables, Payment Out vouchers (سندات صرف للمورد).
   - **Debt Aging Analysis (تحليل أعمار الديون)**: Standard buckets (0-30 Days, 31-60 Days, 61-90 Days, 90+ Days overdue) for each customer/supplier and portfolio-wide.
5. **Thermal Receipt & PDF Printing**:
   - Native ESC/POS 80mm and 58mm Bluetooth/Wi-Fi thermal receipt generator.
   - Crisp ZATCA QR code embedding and print preview.
5. **Role-Based Access Control (RBAC)**:
   - **Super Admin**: Complete unrestricted system access.
   - **Admin / Branch Manager**: User, inventory, and branch oversight.
   - **Van Salesman / Driver**: Restricted to assigned van stock, spot invoicing, customer route visits. Cost prices and sensitive margins are strictly hidden.
   - **Accountant**: Financial reports, ledger approvals, ZATCA tax return.
6. **Enterprise Cloud Backend (`mandhoob_server`)**:
   - Node.js / TypeScript REST API.
   - Multi-device delta synchronization (`/api/sync/push` & `/api/sync/pull`).
   - Conflict resolution and offline change queue.

---

## 📁 Repository Structure

```text
MAndhoob App/
├── mandhoob_mobile_desktop/         # Flutter Mobile & Desktop Application
│   ├── lib/
│   │   ├── main.dart                # Application entrypoint & multi-tab navigation
│   │   ├── core/
│   │   │   ├── constants/           # AppColors (Vyapar Navy & Green), AppStrings
│   │   │   ├── theme/               # Material 3 light theme & typography
│   │   │   ├── localization/        # Arabic (RTL) & English localization
│   │   │   └── utils/
│   │   │       ├── zatca_encoder.dart    # ZATCA TLV Base64 QR Code generator
│   │   │       └── esc_pos_generator.dart # Thermal 80mm/58mm ESC/POS byte builder
│   │   ├── models/                  # Domain Models
│   │   │   ├── user_model.dart      # Roles (Super Admin, Admin, Salesman, Accountant) & RBAC
│   │   │   ├── customer_model.dart  # 15-digit VAT, CR, credit limits, routes, balance
│   │   │   ├── supplier_model.dart  # Supplier payables & ledgers
│   │   │   ├── product_model.dart   # Barcodes, SKUs, batches, expiry, multi-units
│   │   │   ├── warehouse_model.dart # Central Warehouse vs Van Warehouses
│   │   │   ├── stock_transfer_model.dart # WH -> Van morning loading
│   │   │   ├── invoice_model.dart   # Tax Invoices, Simplified Invoices, Quotations, Returns
│   │   │   ├── invoice_item_model.dart # Items, quantities, prices, 15% VAT
│   │   │   └── expense_model.dart   # Fuel, per diem, vehicle maintenance
│   │   ├── services/
│   │   │   ├── auth_service.dart    # User session & role switcher
│   │   │   ├── database_service.dart# Local offline database repository & seed data
│   │   │   ├── sync_service.dart    # Bi-directional cloud sync engine & offline queue
│   │   │   └── printer_service.dart # Bluetooth thermal & A4 printer manager
│   │   ├── widgets/
│   │   │   ├── adaptive_scaffold.dart # Responsive mobile & tablet layout
│   │   │   └── permission_gate.dart # Permission guard widget
│   │   └── screens/
│   │       ├── dashboard/           # Financial KPIs, Cash float, Receivables, Quick actions
│   │       ├── sales/               # Vyapar invoice creator, ZATCA QR, Thermal receipt preview
│   │       ├── purchase/            # Supplier payables & purchase bills
│   │       ├── inventory/           # Stock levels, Van loading, batch tracking
│   │       ├── customers/           # Statement of Account (كشف حساب), Credit limits
│   │       ├── expenses/            # Fuel, fleet maintenance, petty cash
│   │       ├── reports/             # Official ZATCA VAT Return (Box 1-14), Day Book
│   │       ├── search/              # Global search & multi-date range filters
│   │       └── settings/            # Company profile, ZATCA keys, Printer setup, RBAC
│   ├── test/
│   │   └── zatca_test.dart          # Automated test for ZATCA TLV QR & ESC/POS printer
│   └── pubspec.yaml                 # Dependencies and assets
│
└── mandhoob_server/                 # Enterprise Cloud Backend
    ├── src/
    │   ├── index.ts                 # Express server & API routes
    │   ├── middlewares/auth.ts      # Authentication & RBAC guards
    │   ├── controllers/
    │   │   ├── salesController.ts   # Invoice endpoints
    │   │   └── syncController.ts    # Multi-device cloud sync push/pull
    │   └── models/types.ts          # TypeScript interfaces
    ├── package.json
    └── tsconfig.json
```

---

## ⚡ How to Run

### 1. Running the Flutter App (`mandhoob_mobile_desktop`)
```powershell
cd "d:\MAndhoob App\mandhoob_mobile_desktop"
flutter run
```
*Supports Windows Desktop, macOS, Android, and iOS.*

### 2. Running Automated Tests (ZATCA QR & ESC/POS)
```powershell
cd "d:\MAndhoob App"
dart run mandhoob_mobile_desktop/test/zatca_test.dart
```

### 3. Running the Enterprise Cloud Server (`mandhoob_server`)
```powershell
cd "d:\MAndhoob App\mandhoob_server"
npm install
npm run dev
```
Server runs on `http://localhost:4000`.

---

## 🇸🇦 Saudi ZATCA Compliance Details

- **TLV Structure**:
  - `Tag 1`: Seller Name (`UTF-8`)
  - `Tag 2`: 15-Digit VAT Number (`3XXXXXXXXXXXXX3`)
  - `Tag 3`: ISO-8601 Timestamp
  - `Tag 4`: Invoice Total (inclusive of 15% VAT)
  - `Tag 5`: VAT Total
  - `Tags 6-8`: Cryptographic stamp & public key (Phase 2 readiness)
- **Output**: Pure Base64 encoded byte string rendered inside the QR code matrix.
- **Printed Receipt**: Validated against ZATCA Fatoora scanning app.

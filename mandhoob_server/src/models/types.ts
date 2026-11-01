export type UserRole = 'super_admin' | 'admin' | 'salesman' | 'accountant';

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  assignedVanId?: string;
  assignedVanName?: string;
}

export interface InvoiceItem {
  productId: string;
  productNameAr: string;
  productNameEn: string;
  quantity: number;
  unit: string;
  unitPrice: number;
  discount: number;
  vatRatePercent: number;
  lineSubtotal: number;
  lineVatAmount: number;
  lineTotal: number;
}

export interface Invoice {
  id: string;
  invoiceNumber: string;
  type: 'simplified' | 'tax_invoice' | 'quotation' | 'sales_return' | 'delivery_challan';
  invoiceDate: string;
  customerId: string;
  customerNameAr: string;
  customerVatNumber?: string;
  warehouseId: string; // E.g. 'VAN-01'
  warehouseName: string;
  salesmanId: string;
  salesmanName: string;
  items: InvoiceItem[];
  subtotal: number;
  vatTotal: number;
  discountTotal: number;
  grandTotal: number;
  paymentMethod: 'cash' | 'mada' | 'bank_transfer' | 'credit';
  paymentStatus: 'paid' | 'unpaid' | 'partial';
  paidAmount: number;
  zatcaQrBase64: string;
  updatedAt: string;
}

export interface SyncPushPayload {
  deviceId: string;
  lastSyncedTimestamp: string;
  invoices: Invoice[];
  expenses: any[];
  stockTransfers: any[];
}

export interface SyncPullResponse {
  serverTimestamp: string;
  invoices: Invoice[];
  products: any[];
  customers: any[];
  warehouses: any[];
}

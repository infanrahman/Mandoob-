import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth';
import { Invoice } from '../models/types';

// In-Memory Cloud Database
export const cloudInvoices: Invoice[] = [
  {
    id: 'INV-2026-001',
    invoiceNumber: 'INV-2026-001',
    type: 'simplified',
    invoiceDate: new Date().toISOString(),
    customerId: 'CUST-102',
    customerNameAr: 'تموينات الأمانة الحديثة',
    customerVatNumber: '310554433200003',
    warehouseId: 'VAN-01',
    warehouseName: 'سيارة 1 - الرياض شمال',
    salesmanId: 'USR-003',
    salesmanName: 'محمد الدوسري',
    items: [
      {
        productId: 'PRD-001',
        productNameAr: 'حليب المراعي طازج كامل الدسم 1 لتر',
        productNameEn: 'Almarai Fresh Milk Full Fat 1L',
        quantity: 24,
        unit: 'حبة',
        unitPrice: 5.20,
        discount: 0,
        vatRatePercent: 15,
        lineSubtotal: 124.80,
        lineVatAmount: 18.72,
        lineTotal: 143.52,
      },
    ],
    subtotal: 124.80,
    vatTotal: 18.72,
    discountTotal: 0,
    grandTotal: 143.52,
    paymentMethod: 'cash',
    paymentStatus: 'paid',
    paidAmount: 143.52,
    zatcaQrBase64: 'AQ9TYWxlcyBDb21wYW55Ag8zMTAxMjM0NTY3MDAwMDMDEDIwMjYtMTAtMjlUMTk6MTQ6MDBaBAYxNDMuNTIFBDE4Ljcy',
    updatedAt: new Date().toISOString(),
  },
];

export function getInvoices(req: AuthenticatedRequest, res: Response) {
  const user = req.user!;
  // If salesman, restrict to own van invoices
  if (user.role === 'salesman' && user.assignedVanId) {
    const vanInvoices = cloudInvoices.filter((inv) => inv.warehouseId === user.assignedVanId);
    return res.json({ success: true, count: vanInvoices.length, data: vanInvoices });
  }

  return res.json({ success: true, count: cloudInvoices.length, data: cloudInvoices });
}

export function createInvoice(req: AuthenticatedRequest, res: Response) {
  const invoiceData: Invoice = req.body;
  if (!invoiceData.invoiceNumber || !invoiceData.items || invoiceData.items.length === 0) {
    return res.status(400).json({ success: false, error: 'بيانات الفاتورة غير مكتملة' });
  }

  invoiceData.updatedAt = new Date().toISOString();
  cloudInvoices.unshift(invoiceData);

  return res.status(201).json({
    success: true,
    message: 'تم حفظ الفاتورة في السحابة بنجاح',
    data: invoiceData,
  });
}

import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth';
import { SyncPushPayload, SyncPullResponse } from '../models/types';
import { cloudInvoices } from './salesController';

export function handleSyncPush(req: AuthenticatedRequest, res: Response) {
  const payload: SyncPushPayload = req.body;
  const user = req.user!;

  if (!payload || !payload.invoices) {
    return res.status(400).json({ success: false, error: 'حمولة المزامنة غير صالحة' });
  }

  let mergedCount = 0;
  for (const newInv of payload.invoices) {
    const existingIndex = cloudInvoices.findIndex((inv) => inv.id === newInv.id || inv.invoiceNumber === newInv.invoiceNumber);
    if (existingIndex === -1) {
      newInv.updatedAt = new Date().toISOString();
      cloudInvoices.unshift(newInv);
      mergedCount++;
    }
  }

  return res.json({
    success: true,
    message: `تمت مزامنة ${mergedCount} فاتورة جديدة بنجاح من الجهاز ${payload.deviceId || 'Mobile'}`,
    serverTimestamp: new Date().toISOString(),
  });
}

export function handleSyncPull(req: AuthenticatedRequest, res: Response) {
  const since = req.query.since as string;
  const user = req.user!;

  let filtered = cloudInvoices;
  if (user.role === 'salesman' && user.assignedVanId) {
    filtered = cloudInvoices.filter((inv) => inv.warehouseId === user.assignedVanId);
  }

  if (since) {
    const sinceDate = new Date(since);
    filtered = filtered.filter((inv) => new Date(inv.updatedAt) > sinceDate);
  }

  const response: SyncPullResponse = {
    serverTimestamp: new Date().toISOString(),
    invoices: filtered,
    products: [],
    customers: [],
    warehouses: [],
  };

  return res.json({ success: true, data: response });
}

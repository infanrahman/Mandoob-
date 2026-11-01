import { Request, Response, NextFunction } from 'express';
import { UserRole, User } from '../models/types';

export interface AuthenticatedRequest extends Request {
  user?: User;
}

// Mock Active User Directory
export const MOCK_USERS: Record<string, User> = {
  'usr-super': {
    id: 'USR-001',
    name: 'سلطان القحطاني - Sultan Al-Qahtani',
    email: 'sultan@mandhoob.sa',
    role: 'super_admin',
  },
  'usr-admin': {
    id: 'USR-002',
    name: 'فهد العتيبي - Fahad Al-Otaibi',
    email: 'fahad@mandhoob.sa',
    role: 'admin',
  },
  'usr-sales': {
    id: 'USR-003',
    name: 'محمد الدوسري - Mohammed Al-Dosari',
    email: 'mohammed@mandhoob.sa',
    role: 'salesman',
    assignedVanId: 'VAN-01',
    assignedVanName: 'سيارة 1 - الرياض شمال',
  },
  'usr-acc': {
    id: 'USR-004',
    name: 'عبدالله الشهري - Abdullah Al-Shehri',
    email: 'abdullah@mandhoob.sa',
    role: 'accountant',
  },
};

/**
 * Authentication Middleware: Extracts Authorization Bearer token or User ID header
 */
export function authenticate(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  const userIdHeader = (req.headers['x-user-id'] as string) || 'usr-super';

  const user = MOCK_USERS[userIdHeader] || MOCK_USERS['usr-super'];
  req.user = user;
  next();
}

/**
 * Role-Based Access Control Guard
 */
export function requireRole(allowedRoles: UserRole[]) {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'غير مصرّح: يرجى تسجيل الدخول' });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: `غير مسموح: دورك (${req.user.role}) لا يملك صلاحية الوصول إلى هذه العملية`,
        requiredRoles: allowedRoles,
      });
    }

    next();
  };
}

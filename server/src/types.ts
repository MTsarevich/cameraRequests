import type { firestore } from "firebase-admin";

export type LeadStatus = "new" | "in_progress" | "closed";

export interface NotificationSettings {
  newLeadEnabled: boolean;
  remindersEnabled: boolean;
  quietHoursEnabled: boolean;
  quietStartHour: number;
  quietEndHour: number;
  timezone: string;
  soundEnabled: boolean;
}

export const DEFAULT_NOTIFICATION_SETTINGS: NotificationSettings = {
  newLeadEnabled: true,
  remindersEnabled: true,
  quietHoursEnabled: true,
  quietStartHour: 1,
  quietEndHour: 8,
  timezone: "Europe/Moscow",
  soundEnabled: true,
};

export interface UserDoc {
  displayName?: string;
  fcmTokens?: string[];
  role?: "admin" | "member";
  notificationSettings?: Partial<NotificationSettings>;
}

export interface LeadDoc {
  name: string;
  phone: string;
  email?: string;
  message?: string;
  source: string;
  pageUrl?: string;
  status: LeadStatus;
  createdAt: firestore.Timestamp;
  updatedAt: firestore.Timestamp;
  assignedTo?: string;
  lastRemindedAt?: firestore.Timestamp | null;
  reminderCount: number;
  rawPayload: Record<string, unknown>;
}

"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.db = db;
exports.messaging = messaging;
const admin = __importStar(require("firebase-admin"));
// Reads the service account from FIREBASE_SERVICE_ACCOUNT.
// Accepts either raw JSON or (preferred) a base64-encoded JSON blob.
function loadServiceAccount() {
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
    if (!raw || !raw.trim()) {
        throw new Error("FIREBASE_SERVICE_ACCOUNT env var is not set");
    }
    const text = raw.trim().startsWith("{")
        ? raw
        : Buffer.from(raw, "base64").toString("utf8");
    try {
        return JSON.parse(text);
    }
    catch {
        throw new Error("FIREBASE_SERVICE_ACCOUNT is not valid JSON (or base64 of JSON)");
    }
}
let app;
function getApp() {
    if (!app) {
        app = admin.initializeApp({
            credential: admin.credential.cert(loadServiceAccount()),
        });
    }
    return app;
}
function db() {
    return getApp().firestore();
}
function messaging() {
    return getApp().messaging();
}
//# sourceMappingURL=firebase.js.map
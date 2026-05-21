"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const ingestLead_1 = require("./ingestLead");
const remind_1 = require("./remind");
const app = (0, express_1.default)();
app.use((0, cors_1.default)());
app.use(express_1.default.json({ limit: "64kb" }));
// Health check — also the endpoint the cron pinger keeps warm.
app.get("/", (_req, res) => {
    res.json({ ok: true, service: "cameraRequests-server" });
});
app.post("/ingestLead", (req, res) => {
    (0, ingestLead_1.handleIngestLead)(req, res).catch((err) => {
        console.error("[ingestLead] unhandled error", err);
        if (!res.headersSent)
            res.status(500).json({ error: "internal" });
    });
});
app.post("/cron/remind", (req, res) => {
    (0, remind_1.handleRemind)(req, res).catch((err) => {
        console.error("[remind] unhandled error", err);
        if (!res.headersSent)
            res.status(500).json({ error: "internal" });
    });
});
const port = Number(process.env.PORT) || 3000;
app.listen(port, () => {
    console.log(`[server] listening on port ${port}`);
});
//# sourceMappingURL=index.js.map
/*
 * app.js — Express application setup
 * This file creates the Express app, registers global middleware (CORS, JSON parsing),
 * mounts all API route groups under /api, and attaches error-handling middleware.
 * It does NOT start the server — server.js does that.
 */

const express = require("express");
const cors = require("cors");
const authRoutes = require("./routes/authRoutes");
const appStateRoutes = require("./routes/appStateRoutes");
const userRoutes = require("./routes/userRoutes");
const groupRoutes = require("./routes/groupRoutes");
const expenseRoutes = require("./routes/expenseRoutes");
const summaryRoutes = require("./routes/summaryRoutes");
const friendshipRoutes = require("./routes/friendshipRoutes");
const { notFound, errorHandler } = require("./middleware/errorHandler");

// Create the Express application instance
const app = express();

// Enable Cross-Origin Resource Sharing for all origins
app.use(cors());
// Parse incoming JSON request bodies, limited to 1MB to prevent abuse
app.use(express.json({ limit: "1mb" }));

// Simple health-check endpoint — used by monitoring tools to verify the server is alive
app.get("/health", (_req, res) => {
  res.json({ ok: true });
});

// Mount API route modules — each file under ./routes handles one resource
app.use("/api/auth", authRoutes);
app.use("/api/app-state", appStateRoutes);
app.use("/api/users", userRoutes);
app.use("/api/groups", groupRoutes);
app.use("/api/expenses", expenseRoutes);
app.use("/api/summary", summaryRoutes);
app.use("/api/friends", friendshipRoutes);

// 404 handler — runs when no route matches the request URL
app.use(notFound);
// Global error handler — catches errors forwarded by controllers via next(error)
app.use(errorHandler);

module.exports = app;

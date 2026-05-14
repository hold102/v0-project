/*
 * routes/index.js — Aggregated router
 * Combines all route modules under one router. Currently not used by app.js
 * (which mounts routes individually), but kept as a single-entry alternative.
 */
const express = require("express");

const authRoutes = require("./authRoutes");
const appStateRoutes = require("./appStateRoutes");
const expenseRoutes = require("./expenseRoutes");
const groupRoutes = require("./groupRoutes");
const healthRoutes = require("./healthRoutes");
const userRoutes = require("./userRoutes");
const summaryRoutes = require("./summaryRoutes");

const router = express.Router();

router.use(healthRoutes);
router.use("/api/auth", authRoutes);
router.use("/api/app-state", appStateRoutes);
router.use("/api/users", userRoutes);
router.use("/api/groups", groupRoutes);
router.use("/api/expenses", expenseRoutes);
router.use("/api/summary", summaryRoutes);

module.exports = router;

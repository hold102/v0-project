/*
 * healthRoutes.js — Health-check endpoints
 * GET /health     — mounted at the root
 * GET /api/health — mounted under /api (duplicate for convenience)
 * Both return { status: "ok" } so load balancers / monitoring can check liveness.
 */
const express = require("express");

const { getHealth } = require("../controllers/healthController");

const router = express.Router();

router.get("/health", getHealth);
router.get("/api/health", getHealth);

module.exports = router;

/*
 * summaryRoutes.js — Summary route
 * GET / — returns the current user's cross-group totals (owed/owing/net).
 */
const express = require("express");
const { getSummary } = require("../controllers/summaryController");

const router = express.Router();

router.get("/", getSummary);

module.exports = router;

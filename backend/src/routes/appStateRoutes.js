/*
 * appStateRoutes.js — App state route
 * GET / — returns the full app state (current user, users list, visible groups)
 * This is the main "bootstrap" endpoint the frontend calls on startup.
 */
const express = require("express");
const { getAppState } = require("../controllers/appStateController");

const router = express.Router();

router.get("/", getAppState);

module.exports = router;

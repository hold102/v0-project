/*
 * authRoutes.js — Authentication routes
 * POST /login    — authenticate with email + password
 * POST /register — create a new account (or reuse an existing user)
 */
const express = require("express");
const { login, register } = require("../controllers/authController");

const router = express.Router();

router.post("/login", login);
router.post("/register", register);

module.exports = router;

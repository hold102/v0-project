/*
 * authRoutes.js — Authentication routes
 * POST /login                — authenticate with email + password
 * POST /register             — create a new account
 * GET  /verify?token=...     — verify email address (browser link from email)
 * POST /resend-verification  — resend verification email { email }
 */
const express = require("express");
const { login, register, verifyEmail, resendVerification } = require("../controllers/authController");

const router = express.Router();

router.post("/login", login);
router.post("/register", register);
router.get("/verify", verifyEmail);
router.post("/resend-verification", resendVerification);

module.exports = router;

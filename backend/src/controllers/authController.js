/*
 * authController.js — Thin layer between routes and auth service
 * Controllers extract data from the request and delegate to the service.
 * On success they send the response; on error they forward to the error handler.
 */
const { login: loginService, register: registerService, resendVerification: resendVerificationService } = require("../services/authService");
const { verifyToken } = require("../services/verificationService");

async function register(req, res, next) {
  try {
    const result = await registerService(req.body);
    res.status(201).json(result);  // 201 Created for new resources
  } catch (error) {
    next(error);  // Forward to errorHandler middleware
  }
}

async function login(req, res, next) {
  try {
    const result = await loginService(req.body);
    res.json(result);
  } catch (error) {
    next(error);
  }
}

async function verifyEmail(req, res, next) {
  try {
    const { token } = req.query;
    if (!token) {
      return res.status(400).send(verifyPage(false, "Missing verification token."));
    }
    const result = await verifyToken(token);
    if (result.success) {
      return res.send(verifyPage(true, result.alreadyVerified ? "Already verified." : null));
    }
    return res.status(400).send(verifyPage(false, result.message));
  } catch (error) {
    next(error);
  }
}

async function resendVerification(req, res, next) {
  try {
    await resendVerificationService(req.body);
    res.json({ message: "Verification email sent." });
  } catch (error) {
    next(error);
  }
}

function verifyPage(success, note) {
  const icon = success ? "✅" : "❌";
  const heading = success ? "Email verified!" : "Verification failed";
  const body = success
    ? "Your SplitEase account is now verified. You can close this tab and sign in."
    : note || "Something went wrong.";
  return `<!DOCTYPE html><html><head><meta charset="utf-8"><title>SplitEase</title></head>
<body style="font-family:-apple-system,sans-serif;background:#0f0c29;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;">
  <div style="background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.12);border-radius:20px;padding:48px 40px;max-width:400px;text-align:center;">
    <div style="font-size:48px;margin-bottom:16px;">${icon}</div>
    <h1 style="color:#fff;font-size:22px;margin:0 0 12px;">${heading}</h1>
    <p style="color:rgba(255,255,255,0.6);font-size:15px;line-height:1.5;margin:0;">${body}</p>
  </div>
</body></html>`;
}

module.exports = {
  login,
  register,
  verifyEmail,
  resendVerification,
};

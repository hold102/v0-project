/*
 * emailService.js — Transactional email via Brevo REST API
 * Set BREVO_API_KEY in .env to enable. If not set, the link is logged to console
 * instead (useful for local dev without an email account).
 *
 * Setup:
 *   1. Sign up at brevo.com (free tier: 300 emails/day)
 *   2. Go to SMTP & API → API Keys → create a key
 *   3. Verify your sender email under Senders & Domains
 *   4. Add BREVO_API_KEY=xkeysib-... to your .env
 */
const { brevoApiKey, appBaseUrl } = require("../config/env");

const FROM_EMAIL = process.env.FROM_EMAIL || "liangyao0808@gmail.com";
const FROM_NAME = process.env.FROM_NAME || "SplitEase";

async function sendVerificationEmail(toEmail, name, token) {
  const verifyUrl = `${appBaseUrl}/api/auth/verify?token=${token}`;

  console.log(`[emailService] Sending verification email to ${toEmail}, apiKey set: ${!!brevoApiKey}`);

  if (!brevoApiKey) {
    console.log(`[emailService] BREVO_API_KEY not set. Verification link for ${toEmail}:`);
    console.log(`  ${verifyUrl}`);
    return;
  }

  const html = `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:#0f0c29;margin:0;padding:40px 20px;">
  <div style="max-width:480px;margin:0 auto;background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.12);border-radius:20px;padding:40px;">
    <div style="font-size:36px;text-align:center;margin-bottom:16px;">💸</div>
    <h1 style="color:#fff;font-size:22px;font-weight:700;margin:0 0 8px;">Verify your email</h1>
    <p style="color:rgba(255,255,255,0.6);font-size:15px;line-height:1.5;margin:0 0 28px;">
      Hi ${name}, tap the button below to verify your SplitEase account. This link expires in 24 hours.
    </p>
    <a href="${verifyUrl}" style="display:block;text-align:center;background:linear-gradient(135deg,#764ba2,#667eea);color:#fff;text-decoration:none;font-weight:600;font-size:15px;padding:14px 24px;border-radius:12px;margin-bottom:24px;">
      Verify Email Address
    </a>
    <p style="color:rgba(255,255,255,0.35);font-size:12px;text-align:center;margin:0;">
      If you didn't create a SplitEase account, you can safely ignore this email.
    </p>
  </div>
</body>
</html>`;

  const res = await fetch("https://api.brevo.com/v3/smtp/email", {
    method: "POST",
    headers: {
      "api-key": brevoApiKey,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      sender: { name: FROM_NAME, email: FROM_EMAIL },
      to: [{ email: toEmail, name }],
      subject: "Verify your SplitEase account",
      htmlContent: html,
    }),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(`Email send failed (${res.status}): ${err.message || JSON.stringify(err)}`);
  }

  console.log(`[emailService] Verification email sent successfully to ${toEmail}`);
}

module.exports = { sendVerificationEmail };

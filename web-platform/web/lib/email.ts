import 'server-only'
import nodemailer from 'nodemailer'
import { siteConfig } from '@/lib/site-config'

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST ?? '127.0.0.1',
  port: Number(process.env.SMTP_PORT ?? 25),
  secure: process.env.SMTP_SECURE === 'true',
  auth: process.env.SMTP_USER
    ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS ?? '' }
    : undefined,
})

const FROM = process.env.SMTP_FROM ?? 'OpenRP Framework <noreply@example.com>'
const SITE = siteConfig.name

function wrap(body: string): string {
  return `<!DOCTYPE html>
<html><body style="margin:0;padding:0;background:#0d1117;font-family:Arial,sans-serif;">
<div style="max-width:520px;margin:40px auto;background:#161b22;border-radius:10px;overflow:hidden;border:1px solid #30363d;">
  <div style="background:#1a2332;padding:24px 32px;border-bottom:1px solid #30363d;">
    <span style="color:#e6edf3;font-size:18px;font-weight:700;">${SITE}</span>
  </div>
  <div style="padding:32px;color:#c9d1d9;font-size:14px;line-height:1.6;">
    ${body}
  </div>
  <div style="padding:16px 32px;border-top:1px solid #30363d;color:#6e7681;font-size:12px;">
    If you did not request this email you can safely ignore it.
  </div>
</div>
</body></html>`
}

export async function sendVerificationEmail(
  to: string,
  accountId: number,
  code: string,
  siteUrl: string,
): Promise<void> {
  const link = `${siteUrl}/ucp/verify?id=${accountId}&code=${encodeURIComponent(code)}`
  await transporter.sendMail({
    from: FROM,
    to,
    subject: `Verify your ${SITE} account`,
    html: wrap(`
      <h2 style="color:#e6edf3;margin-top:0;">Verify Your Email</h2>
      <p>Thanks for registering! Click the button below to verify your email address and activate your account.</p>
      <div style="text-align:center;margin:28px 0;">
        <a href="${link}"
           style="background:#3b82f6;color:#fff;padding:12px 28px;border-radius:6px;text-decoration:none;font-weight:600;display:inline-block;">
          Verify Email Address
        </a>
      </div>
      <p style="color:#6e7681;font-size:12px;">Or copy this link into your browser:<br>
        <a href="${link}" style="color:#58a6ff;word-break:break-all;">${link}</a>
      </p>
    `),
  })
}

export async function sendPasswordResetEmail(
  to: string,
  token: string,
  siteUrl: string,
): Promise<void> {
  const link = `${siteUrl}/ucp/reset/${encodeURIComponent(token)}`
  await transporter.sendMail({
    from: FROM,
    to,
    subject: `Reset your ${SITE} password`,
    html: wrap(`
      <h2 style="color:#e6edf3;margin-top:0;">Password Reset</h2>
      <p>We received a request to reset your password. Click the button below to choose a new one.</p>
      <div style="text-align:center;margin:28px 0;">
        <a href="${link}"
           style="background:#3b82f6;color:#fff;padding:12px 28px;border-radius:6px;text-decoration:none;font-weight:600;display:inline-block;">
          Reset Password
        </a>
      </div>
      <p style="color:#6e7681;font-size:12px;">
        This link expires in 1 hour. If you did not request a password reset, you can safely ignore this email.
      </p>
    `),
  })
}

/** Email a short-lived login or security-settings challenge. */
export async function sendLoginCode(to: string, code: string): Promise<void> {
  await transporter.sendMail({ from: FROM, to, subject: 'Your ' + SITE + ' verification code', text: 'Your code is ' + code + '. It expires in 5 minutes. Never share this code.' })
}

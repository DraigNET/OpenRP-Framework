import { timingSafeEqual } from 'node:crypto'
import { prisma } from '@/lib/prisma'
import Link from 'next/link'

export default async function VerifyPage({
  searchParams,
}: {
  searchParams: Promise<{ id?: string; code?: string }>
}) {
  const { id, code } = await searchParams
  const accountId = Number(id)

  if (!Number.isSafeInteger(accountId) || accountId <= 0 || !code || !/^[a-f0-9]{32}$/.test(code)) {
    return <VerifyResult ok={false} message="Invalid verification link." />
  }

  const account = await prisma.account.findUnique({
    where: { account_id: accountId },
    select: { account_email_verified: true, account_email_verifycode: true, account_email_verify_sent_at: true },
  })

  if (!account) {
    return <VerifyResult ok={false} message="Invalid verification link." />
  }

  if (account.account_email_verified) {
    return <VerifyResult ok={true} message="Your email is already verified. You can log in normally." />
  }

  if (!/^[a-f0-9]{32}$/.test(account.account_email_verifycode) || !timingSafeEqual(Buffer.from(account.account_email_verifycode), Buffer.from(code)) || !account.account_email_verify_sent_at || account.account_email_verify_sent_at < Math.floor(Date.now() / 1000) - 86400) {
    return <VerifyResult ok={false} message="Invalid or expired verification link." />
  }

  await prisma.account.updateMany({
    where: { account_id: accountId, account_email_verifycode: code, account_email_verified: 0 },
    data: { account_email_verified: 1, account_email_verifycode: 'Undefined' },
  })

  return <VerifyResult ok={true} message="Your email has been verified! You can now log in." />
}

function VerifyResult({ ok, message }: { ok: boolean; message: string }) {
  return (
    <div className="ucp-login-body">
      <div className="ucp-login-wrapper">
        <div className="ucp-login-card" style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 48, marginBottom: 16 }}>{ok ? '✅' : '❌'}</div>
          <h1>OpenRP Framework UCP</h1>
          <h2>{ok ? 'Email Verified' : 'Verification Failed'}</h2>
          <p style={{ color: 'var(--text-2)', marginBottom: 24 }}>{message}</p>
          <Link href="/ucp/login" className="ucp-btn ucp-btn-primary"
            style={{ display: 'inline-flex', justifyContent: 'center' }}>
            Go to Login
          </Link>
        </div>
      </div>
    </div>
  )
}

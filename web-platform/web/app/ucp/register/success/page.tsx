import Link from 'next/link'

export default function RegisterSuccessPage() {
  return (
    <div className="ucp-login-body">
      <div className="ucp-login-wrapper">
        <div className="ucp-login-card" style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 48, marginBottom: 16 }}>✉️</div>
          <h1>OpenRP Framework UCP</h1>
          <h2>Account Created!</h2>
          <p style={{ color: 'var(--text-2)', marginBottom: 24 }}>
            Your account has been created. We&apos;ve sent a verification email — please
            check your inbox (and spam folder) and click the link to activate your account.
          </p>
          <Link href="/ucp/login" className="ucp-btn ucp-btn-primary"
            style={{ display: 'inline-flex', justifyContent: 'center' }}>
            Continue to Login
          </Link>
        </div>
      </div>
    </div>
  )
}

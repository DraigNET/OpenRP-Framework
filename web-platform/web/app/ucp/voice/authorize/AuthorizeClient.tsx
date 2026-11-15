'use client'

import { useEffect, useState } from 'react'

/** Hands the auth code to the desktop app via deep link, with a manual fallback. */
export default function AuthorizeClient({ code }: { code: string }) {
  const [opened, setOpened] = useState(false)
  const deepLink = `orp-dispatch://auth?code=${encodeURIComponent(code)}`

  useEffect(() => {
    // Auto-launch the app. Browsers require this be tied to navigation; if it's
    // blocked the user can click the button below.
    window.location.href = deepLink
    setOpened(true)
  }, [deepLink])

  return (
    <div className="ucp-login-body">
      <div className="ucp-login-wrapper">
        <div className="ucp-login-card" style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 44, marginBottom: 12 }}>🎙️</div>
          <h1>OpenRP Framework Dispatch</h1>
          <h2>{opened ? 'Opening OpenRP Framework Dispatch…' : 'Connect'}</h2>
          <p style={{ color: 'var(--text-2)', marginBottom: 20 }}>
            If the app didn&apos;t open automatically, click below.
          </p>
          <a href={deepLink} className="ucp-btn ucp-btn-primary"
            style={{ display: 'inline-flex', justifyContent: 'center' }}>
            Open OpenRP Framework Dispatch
          </a>
          <p className="ucp-login-footer" style={{ marginTop: 18, fontSize: 12 }}>
            You can close this tab once the app has connected.
          </p>
        </div>
      </div>
    </div>
  )
}

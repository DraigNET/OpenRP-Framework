'use client'
import { useState } from 'react'
/** Copy the configured address; report clipboard failures without claiming success. */
export default function CopyIpButton({ address }: { address: string }) {
  const [message, setMessage] = useState('Copy address')
  return <div className="server-address"><code>{address}</code><button className="site-btn site-btn-quiet" onClick={async () => { try { await navigator.clipboard.writeText(address); setMessage('Address copied') } catch { setMessage('Select and copy the address above') } }}>{message}</button><span className="sr-only" aria-live="polite">{message}</span></div>
}


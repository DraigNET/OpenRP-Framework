import type { ReactNode } from 'react'
import './ucp.css'

// Applies the saved accent colour before first paint so there is no flash of the default.
const ACCENT_BOOT = `try{var h=localStorage.getItem('ucpHue');if(h)document.documentElement.style.setProperty('--hue',h)}catch(e){}`

export default function UcpRootLayout({ children }: { children: ReactNode }) {
  return (
    <>
      <link rel="preconnect" href="https://fonts.googleapis.com" />
      <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
      <link
        rel="stylesheet"
        href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&family=JetBrains+Mono:wght@500&display=swap"
      />
      <link
        rel="stylesheet"
        href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css"
        crossOrigin="anonymous"
      />
      <script dangerouslySetInnerHTML={{ __html: ACCENT_BOOT }} />
      {children}
    </>
  )
}

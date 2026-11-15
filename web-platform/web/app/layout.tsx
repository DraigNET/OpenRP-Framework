import type { Metadata } from 'next'
import './root.css'

export const metadata: Metadata = {
  title: 'OpenRP Framework',
  description: 'OpenRP Framework — roleplay framework for open.mp',
  icons: { icon: '/favicon.png' },
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}

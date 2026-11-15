import { env } from '@/lib/env'
import { auth } from '@/auth'
import { redirect, notFound } from 'next/navigation'
import { mintAuthCode } from '@/lib/voice-auth'
import AuthorizeClient from './AuthorizeClient'

export const dynamic = 'force-dynamic'

/**
 * Entry point for the OpenRP Framework Dispatch desktop app's "Connect with UCP" flow.
 * The user is already (or gets) logged into the UCP here; we mint a short-lived
 * auth code and hand it back to the app via the orp-dispatch:// deep link.
 */
export default async function VoiceAuthorizePage() {
  if (!env.voiceEnabled) notFound()
  const session = await auth()
  if (!session) {
    redirect(`/ucp/login?callbackUrl=${encodeURIComponent('/ucp/voice/authorize')}`)
  }
  const code = await mintAuthCode(session.user.id)
  return <AuthorizeClient code={code} />
}

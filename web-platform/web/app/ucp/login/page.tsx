import { env } from '@/lib/env'
import LoginForm from './LoginForm'

type SearchParams = Promise<{ error?: string; callbackUrl?: string }>

export default async function LoginPage({ searchParams }: { searchParams: SearchParams }) {
  const params = await searchParams
  return (
    <LoginForm
      discordEnabled={env.discordEnabled}
      urlError={params.error}
      callbackUrl={params.callbackUrl ?? '/ucp'}
    />
  )
}

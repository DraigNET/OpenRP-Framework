import RegisterForm from './RegisterForm'

export const dynamic = 'force-dynamic'

export default function RegisterPage() {
  // Read at runtime on the server (not a NEXT_PUBLIC build-time inline) and pass
  // to the client form. The widget renders only when reCAPTCHA is configured.
  const siteKey = process.env.RECAPTCHA_SITE_KEY ?? null
  return <RegisterForm recaptchaSiteKey={siteKey} />
}

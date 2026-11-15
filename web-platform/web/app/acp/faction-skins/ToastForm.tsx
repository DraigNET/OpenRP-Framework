'use client'

import { useRef, useState, useTransition, type CSSProperties, type ReactNode } from 'react'

/**
 * A form whose server action returns a short message; the message slides in as a toast from the
 * right and slides out again a couple of seconds later.
 */
export function ToastForm({ action, children, id, className, style }: {
  action: (formData: FormData) => Promise<string>
  children: ReactNode
  id?: string
  className?: string
  style?: CSSProperties
}) {
  const [message, setMessage] = useState('')
  const [shown, setShown] = useState(false)
  const [, startTransition] = useTransition()
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null)

  function submit(formData: FormData) {
    startTransition(async () => {
      const text = await action(formData)
      setMessage(text || 'Saved')
      setShown(true)
      if (timer.current) clearTimeout(timer.current)
      timer.current = setTimeout(() => setShown(false), 2600)
    })
  }

  return (
    <>
      <form id={id} className={className} style={style} action={submit}>{children}</form>
      <div className={`acp-toast${shown ? ' is-in' : ''}`} role="status" aria-live="polite">
        <i className="fa-solid fa-circle-check" /> {message}
      </div>
    </>
  )
}

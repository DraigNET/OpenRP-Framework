'use client'

import { useActionState, useState, useRef } from 'react'
import Link from 'next/link'
import { createCharacterAction } from './actions'

const STEPS = ['Name', 'Identity', 'Appearance', 'Description']

const RACES = [{ v: 1, l: 'White' }, { v: 2, l: 'Black' }, { v: 3, l: 'Latino' }, { v: 4, l: 'Asian' }]
const HAIRS = [{ v: 1, l: 'None' }, { v: 2, l: 'Black' }, { v: 3, l: 'Brown' }, { v: 4, l: 'Blonde' }, { v: 5, l: 'White' }, { v: 6, l: 'Grey' }, { v: 7, l: 'Red' }]
const EYES = [{ v: 1, l: 'Amber' }, { v: 2, l: 'Blue' }, { v: 3, l: 'Brown' }, { v: 4, l: 'Grey' }, { v: 5, l: 'Green' }, { v: 6, l: 'Hazel' }]
const BODIES = [{ v: 1, l: 'Skinny' }, { v: 2, l: 'Slim' }, { v: 3, l: 'Normal' }, { v: 4, l: 'Plump' }, { v: 5, l: 'Obese' }, { v: 6, l: 'Muscular' }]

const NAME_RE = /^[A-Za-z]+$/

function FieldError({ error }: { error?: string }) {
  if (!error) return null
  return <p style={{ color: '#f87171', fontSize: 12, marginTop: 4 }}>{error}</p>
}

function SelectGroup<T extends { v: number; l: string }>({ name, options, value, onChange }: { name: string; options: T[]; value: number; onChange: (v: number) => void }) {
  return (
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
      {options.map(o => (
        <button key={o.v} type="button" onClick={() => onChange(o.v)}
          className={`ucp-btn ${value === o.v ? 'ucp-btn-primary' : 'ucp-btn-outline'}`}
          style={{ padding: '6px 14px', fontSize: 13 }}>
          {o.l}
        </button>
      ))}
      <input type="hidden" name={name} value={value} />
    </div>
  )
}

export default function CreateCharacterForm() {
  const [state, action, pending] = useActionState(createCharacterAction, undefined)
  const [step, setStep] = useState(0)
  const [sex, setSex] = useState(1)
  const [race, setRace] = useState(1)
  const [hair, setHair] = useState(2)
  const [eyes, setEyes] = useState(3)
  const [body, setBody] = useState(3)

  const [errors, setErrors] = useState<Record<string, string>>({})
  const [checking, setChecking] = useState(false)

  const firstRef  = useRef<HTMLInputElement>(null)
  const lastRef   = useRef<HTMLInputElement>(null)
  const ageRef    = useRef<HTMLInputElement>(null)
  const heightRef = useRef<HTMLInputElement>(null)
  const descRef   = useRef<HTMLTextAreaElement>(null)

  function clearError(key: string) {
    setErrors(e => { const n = { ...e }; delete n[key]; return n })
  }

  async function validateAndNext() {
    const errs: Record<string, string> = {}

    if (step === 0) {
      const first = firstRef.current?.value.trim() ?? ''
      const last  = lastRef.current?.value.trim() ?? ''
      if (!first) errs.first_name = 'First name is required.'
      else if (!NAME_RE.test(first)) errs.first_name = 'Letters only.'
      if (!last) errs.last_name = 'Last name is required.'
      else if (!NAME_RE.test(last)) errs.last_name = 'Letters only.'

      if (Object.keys(errs).length === 0) {
        setChecking(true)
        try {
          const res = await fetch(`/api/characters/check-name?name=${encodeURIComponent(`${first}_${last}`)}`)
          const data = await res.json()
          if (!data.available) errs.first_name = 'A character with that name already exists.'
        } catch {
          errs.first_name = 'Could not verify name — try again.'
        }
        setChecking(false)
      }
    }

    if (step === 1) {
      const age = Number(ageRef.current?.value)
      if (!age) errs.age = 'Age is required.'
      else if (age < 16 || age > 60) errs.age = 'Age must be between 16 and 60.'
    }

    if (step === 2) {
      const height = Number(heightRef.current?.value)
      if (!height) errs.height = 'Height is required.'
      else if (height < 140 || height > 199) errs.height = 'Height must be between 140 and 199 cm.'
    }

    if (Object.keys(errs).length > 0) {
      setErrors(errs)
      return
    }

    setErrors({})
    setStep(s => s + 1)
  }

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    // Block native submission on any step before the last
    if (step < STEPS.length - 1) {
      e.preventDefault()
      return
    }
    const desc = descRef.current?.value.trim() ?? ''
    if (!desc) {
      e.preventDefault()
      setErrors({ desc: 'A character description is required.' })
    }
  }

  return (
    <div style={{ maxWidth: 560 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
        <Link href="/ucp/characters" className="ucp-btn ucp-btn-outline" style={{ padding: '5px 12px', fontSize: 12 }}>← Characters</Link>
        <h1 style={{ margin: 0, fontSize: 20, fontWeight: 700 }}>Create Character</h1>
      </div>

      {/* Step indicator */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 24 }}>
        {STEPS.map((s, i) => (
          <div key={s} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <button type="button" onClick={() => i < step && setStep(i)} style={{
              width: 28, height: 28, borderRadius: '50%', border: 'none',
              cursor: i < step ? 'pointer' : 'default', fontSize: 12, fontWeight: 700,
              background: i === step ? 'var(--accent)' : i < step ? '#22c55e' : 'var(--bg-input)',
              color: i <= step ? '#fff' : 'var(--text-3)',
            }}>
              {i < step ? '✓' : i + 1}
            </button>
            {i < STEPS.length - 1 && (
              <div style={{ height: 1, width: 32, background: i < step ? '#22c55e' : 'var(--border-sub)' }} />
            )}
          </div>
        ))}
        <span style={{ marginLeft: 8, fontSize: 13, color: 'var(--text-2)' }}>{STEPS[step]}</span>
      </div>

      {state?.errors?.general && (
        <div className="ucp-alert ucp-alert-error" style={{ marginBottom: 16 }}>{state.errors.general}</div>
      )}

      <form action={action} onSubmit={handleSubmit} className="ucp-card" style={{ padding: 24 }}>

        {/* Step 0: Name */}
        <div className={step !== 0 ? 'ucp-hidden' : ''}>
          <h2 className="ucp-section-title">Character Name</h2>
          <p style={{ fontSize: 13, color: 'var(--text-2)', marginBottom: 16 }}>
            Names must be in <strong style={{ color: 'var(--text-1)' }}>First_Last</strong>{' '}
            format. Use a realistic roleplay name.
          </p>
          <div className="ucp-form" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
            <div>
              <label>First Name</label>
              <input ref={firstRef} name="first_name" type="text" placeholder="John"
                onChange={() => clearError('first_name')} />
              <FieldError error={errors.first_name ?? state?.errors?.first_name} />
            </div>
            <div>
              <label>Last Name</label>
              <input ref={lastRef} name="last_name" type="text" placeholder="Smith"
                onChange={() => clearError('last_name')} />
              <FieldError error={errors.last_name ?? state?.errors?.last_name} />
            </div>
          </div>
        </div>

        {/* Step 1: Identity */}
        <div className={step !== 1 ? 'ucp-hidden' : ''}>
          <h2 className="ucp-section-title">Identity</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
            <div>
              <p style={{ fontSize: 13, color: 'var(--text-2)', marginBottom: 8 }}>Gender</p>
              <div style={{ display: 'flex', gap: 10 }}>
                {[{ v: 1, l: 'Male' }, { v: 2, l: 'Female' }].map(o => (
                  <button key={o.v} type="button" onClick={() => setSex(o.v)}
                    className={`ucp-btn ${sex === o.v ? 'ucp-btn-primary' : 'ucp-btn-outline'}`}
                    style={{ padding: '6px 20px' }}>
                    {o.l}
                  </button>
                ))}
              </div>
              <input type="hidden" name="sex" value={sex} />
            </div>
            <div className="ucp-form">
              <label>Age <span style={{ color: 'var(--text-3)', fontWeight: 400 }}>(16–60)</span></label>
              <input ref={ageRef} name="age" type="number" min={16} max={60} defaultValue={25} style={{ width: 90 }}
                onChange={() => clearError('age')} />
              <FieldError error={errors.age ?? state?.errors?.age} />
            </div>
            <div>
              <p style={{ fontSize: 13, color: 'var(--text-2)', marginBottom: 8 }}>Race</p>
              <SelectGroup name="race" options={RACES} value={race} onChange={setRace} />
            </div>
          </div>
        </div>

        {/* Step 2: Appearance */}
        <div className={step !== 2 ? 'ucp-hidden' : ''}>
          <h2 className="ucp-section-title">Appearance</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
            <div className="ucp-form">
              <label>Height <span style={{ color: 'var(--text-3)', fontWeight: 400 }}>(140–199 cm)</span></label>
              <input ref={heightRef} name="height" type="number" min={140} max={199} defaultValue={175} style={{ width: 90 }}
                onChange={() => clearError('height')} />
              <FieldError error={errors.height} />
            </div>
            <div>
              <p style={{ fontSize: 13, color: 'var(--text-2)', marginBottom: 8 }}>Hair Colour</p>
              <SelectGroup name="hair" options={HAIRS} value={hair} onChange={setHair} />
            </div>
            <div>
              <p style={{ fontSize: 13, color: 'var(--text-2)', marginBottom: 8 }}>Eye Colour</p>
              <SelectGroup name="eyes" options={EYES} value={eyes} onChange={setEyes} />
            </div>
            <div>
              <p style={{ fontSize: 13, color: 'var(--text-2)', marginBottom: 8 }}>Body Type</p>
              <SelectGroup name="body" options={BODIES} value={body} onChange={setBody} />
            </div>
          </div>
        </div>

        {/* Step 3: Description */}
        <div className={step !== 3 ? 'ucp-hidden' : ''}>
          <h2 className="ucp-section-title">Character Description</h2>
          <p style={{ fontSize: 13, color: 'var(--text-2)', marginBottom: 12 }}>
            Write a short IC physical description of your character as others would see them. Max 255 characters.
          </p>
          <div className="ucp-form">
            <textarea ref={descRef} name="desc" rows={5} maxLength={255}
              placeholder="A tall man in his late twenties with short brown hair and a lean build…"
              style={{ resize: 'none', width: '100%' }}
              onChange={() => clearError('desc')} />
            <FieldError error={errors.desc} />
          </div>
        </div>

        {/* Navigation */}
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 24 }}>
          <button type="button" onClick={() => { setErrors({}); setStep(s => Math.max(0, s - 1)) }}
            disabled={step === 0}
            className="ucp-btn ucp-btn-outline"
            style={{ opacity: step === 0 ? 0.4 : 1 }}>
            Back
          </button>
          {step < STEPS.length - 1 ? (
            <button type="button" onClick={validateAndNext} disabled={checking}
              className="ucp-btn ucp-btn-primary">
              {checking ? 'Checking…' : 'Next'}
            </button>
          ) : (
            <button type="submit" disabled={pending} className="ucp-btn ucp-btn-primary">
              {pending ? 'Creating…' : 'Create Character'}
            </button>
          )}
        </div>
      </form>
    </div>
  )
}

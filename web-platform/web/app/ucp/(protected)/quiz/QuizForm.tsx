'use client'

import { useActionState } from 'react'
import { submitQuizAction } from './actions'
import type { QuizQuestion } from '@/lib/data/quiz'
import Link from 'next/link'
import { useMemo } from 'react'

function shuffleArray<T>(arr: T[]): T[] {
  const a = [...arr]
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]]
  }
  return a
}

export default function QuizForm({ questions, requiredScore }: { questions: QuizQuestion[]; requiredScore: number }) {
  const [state, action, pending] = useActionState(submitQuizAction, undefined)

  // Shuffle option order once on mount (stable across re-renders)
  const shuffledOptions = useMemo(
    () => questions.map(q => shuffleArray(Object.entries(q.options))),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  )

  return (
    <>
      <p className="ucp-muted rules-quiz-intro">
        You must score {requiredScore} out of {questions.length} to pass. This starter quiz covers basic roleplay concepts. Always read the rules published by your community.
      </p>

      {state?.error && (
        <div className="ucp-alert ucp-alert-error">{state.error}</div>
      )}

      {state?.passed === false && state.score !== undefined && (
        <div className="ucp-alert ucp-alert-error">
          You scored {state.score} out of {state.total}. Please review the rules and try again.
        </div>
      )}

      <form action={action} className="rules-quiz-form" noValidate>
        {questions.map((q, index) => (
          <fieldset key={q.id} className="rules-quiz-question">
            <legend>
              <span>Question {index + 1}</span>
              {q.question}
            </legend>
            <div className="rules-quiz-options">
              {shuffledOptions[index].map(([value, label]) => (
                <label key={value} className="rules-quiz-option">
                  <input
                    type="radio"
                    name={`answers[${index}]`}
                    value={value}
                    required
                  />
                  <span>{label}</span>
                </label>
              ))}
            </div>
          </fieldset>
        ))}

        <div className="rules-quiz-actions">
          <Link href="/ucp/account" className="ucp-btn ucp-btn-outline">Cancel</Link>
          <button type="submit" disabled={pending} className="ucp-btn ucp-btn-primary">
            {pending ? 'Submitting…' : 'Submit Quiz'}
          </button>
        </div>
      </form>
    </>
  )
}

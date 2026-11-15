'use server'

import { auth } from '@/auth'
import { prisma } from '@/lib/prisma'
import { redirect } from 'next/navigation'
import { QUIZ_QUESTIONS, QUIZ_REQUIRED_SCORE } from '@/lib/data/quiz'

export type QuizState = {
  error?: string
  score?: number
  total?: number
  passed?: boolean
} | undefined

export async function submitQuizAction(_prev: QuizState, formData: FormData): Promise<QuizState> {
  const session = await auth()
  if (!session) redirect('/ucp/login')

  const answers: Record<string, string> = {}
  for (const [key, value] of formData.entries()) {
    if (key.startsWith('answers[')) {
      const idx = key.replace('answers[', '').replace(']', '')
      answers[idx] = value as string
    }
  }

  for (let i = 0; i < QUIZ_QUESTIONS.length; i++) {
    if (!answers[String(i)]) return { error: 'Please answer every question before submitting.' }
  }

  let score = 0
  const answerResults = QUIZ_QUESTIONS.map((q, i) => {
    const selected = answers[String(i)] ?? ''
    const isCorrect = selected === q.answer
    if (isCorrect) score++
    return {
      question_number: i + 1,
      question: q.question,
      selected_key: selected,
      selected_answer: q.options[selected] ?? 'Unknown',
      correct_key: q.answer,
      correct_answer: q.options[q.answer],
      is_correct: isCorrect,
    }
  })

  const passed = score >= QUIZ_REQUIRED_SCORE

  const attempt = await prisma.rulesQuizAttempt.create({
    data: {
      account_id: session.user.id,
      score,
      total_questions: QUIZ_QUESTIONS.length,
      required_score: QUIZ_REQUIRED_SCORE,
      passed: passed ? 1 : 0,
      answers_json: JSON.stringify(answerResults),
      created_at: Math.floor(Date.now() / 1000),
    },
  })

  if (passed) {
    await prisma.account.update({
      where: { account_id: session.user.id },
      data: { account_quiz_passed: 1 },
    })
    redirect(`/ucp/quiz?passed=1&attempt=${attempt.attempt_id}`)
  }

  return { score, total: QUIZ_QUESTIONS.length, passed: false }
}

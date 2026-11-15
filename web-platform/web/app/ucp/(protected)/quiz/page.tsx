import { auth } from '@/auth'
import { prisma } from '@/lib/prisma'
import { QUIZ_QUESTIONS, QUIZ_REQUIRED_SCORE } from '@/lib/data/quiz'
import QuizForm from './QuizForm'
import Link from 'next/link'

export default async function QuizPage() {
  const session = await auth()

  const account = await prisma.account.findUnique({
    where: { account_id: session!.user.id },
    select: { account_quiz_passed: true },
  })

  const quizPassed = account?.account_quiz_passed === 1

  const latestAttempt = quizPassed
    ? await prisma.rulesQuizAttempt.findFirst({
        where: { account_id: session!.user.id, passed: 1 },
        orderBy: { created_at: 'desc' },
      })
    : null

  return (
    <div className="ucp-card rules-quiz-card">
      <h2>Rules Quiz</h2>

      {quizPassed ? (
        <>
          <div className="ucp-alert ucp-alert-success">You have passed the rules quiz.</div>

          {latestAttempt && (() => {
            const answers: Array<{
              question_number: number; question: string; is_correct: boolean;
              selected_answer: string; correct_answer: string
            }> = JSON.parse(latestAttempt.answers_json || '[]')
            const scorePct = Math.round((latestAttempt.score / Math.max(1, latestAttempt.total_questions)) * 100)
            return (
              <>
                <div className="rules-quiz-result-summary">
                  <div className="rules-quiz-score-card">
                    <span>Score</span>
                    <strong>{latestAttempt.score}/{latestAttempt.total_questions}</strong>
                  </div>
                  <div className="rules-quiz-score-card">
                    <span>Required</span>
                    <strong>{latestAttempt.required_score}</strong>
                  </div>
                  <div className="rules-quiz-score-card">
                    <span>Accuracy</span>
                    <strong>{scorePct}%</strong>
                  </div>
                </div>
                <div className="rules-quiz-results">
                  {answers.map(a => (
                    <div key={a.question_number} className={`rules-quiz-result ${a.is_correct ? 'is-correct' : 'is-wrong'}`}>
                      <div className="rules-quiz-result-head">
                        <div>
                          <div className="rules-quiz-question-number">Question {a.question_number}</div>
                          <h3>{a.question}</h3>
                        </div>
                        <span className="rules-quiz-result-status">{a.is_correct ? 'Correct' : 'Wrong'}</span>
                      </div>
                      <div className="rules-quiz-answer-list">
                        <div className="rules-quiz-answer-row">
                          <span>Your answer</span>
                          <strong>{a.selected_answer}</strong>
                        </div>
                        {!a.is_correct && (
                          <div className="rules-quiz-answer-row correct-answer">
                            <span>Correct answer</span>
                            <strong>{a.correct_answer}</strong>
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </>
            )
          })()}

          <p><Link href="/ucp/account" className="ucp-btn ucp-btn-primary">Back to Account</Link></p>
        </>
      ) : (
        <QuizForm questions={QUIZ_QUESTIONS} requiredScore={QUIZ_REQUIRED_SCORE} />
      )}
    </div>
  )
}

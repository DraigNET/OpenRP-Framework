/** Starter concepts only. Replace these with your published community rules before launch. */
export interface QuizQuestion { id: string; question: string; options: Record<string, string>; answer: string }
export const QUIZ_QUESTIONS: QuizQuestion[] = [
  { id: 'q1', question: 'What is metagaming?', options: { correct: 'Using out-of-character information to influence in-character decisions.', other: 'Describing what your character can observe.' }, answer: 'correct' },
  { id: 'q2', question: 'What does OOC mean?', options: { correct: 'Out of character.', other: 'An in-character radio channel.' }, answer: 'correct' },
  { id: 'q3', question: 'What should you do when you find a bug?', options: { correct: 'Report it to server staff instead of exploiting it.', other: 'Use it until someone stops you.' }, answer: 'correct' },
  { id: 'q4', question: 'What should you do if a server rule is unclear?', options: { correct: 'Read the published rules and ask staff for clarification.', other: 'Assume another server uses the same rules.' }, answer: 'correct' },
  { id: 'q5', question: 'What is a character?', options: { correct: 'The fictional person you portray in the game world.', other: 'The same identity as the real-world player in every situation.' }, answer: 'correct' },
]
export const QUIZ_REQUIRED_SCORE = Math.ceil(QUIZ_QUESTIONS.length * 0.8)

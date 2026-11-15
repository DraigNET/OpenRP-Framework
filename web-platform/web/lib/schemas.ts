import { z } from 'zod'

/**
 * Centralised input validation. Server actions parse FormData through these
 * instead of hand-rolling checks, so rules are declarative and reused.
 */

/* ── Character creation ──────────────────────────────────────────── */
const namePart = z
  .string()
  .trim()
  .min(2, 'Must be 2–12 characters.')
  .max(12, 'Must be 2–12 characters.')
  .regex(/^[A-Z][a-z]+$/, 'Start with a capital letter; letters only (e.g. John).')

export const characterCreateSchema = z.object({
  first_name: namePart,
  last_name: namePart,
  sex: z.coerce.number().int().refine(v => v === 1 || v === 2, 'Invalid gender.'),
  age: z.coerce.number().int().min(16, 'Age must be 16–60.').max(60, 'Age must be 16–60.'),
  race: z.coerce.number().int().min(1).max(4),
  hair: z.coerce.number().int().min(1).max(7),
  eyes: z.coerce.number().int().min(1).max(6),
  body: z.coerce.number().int().min(1).max(6),
  height: z.coerce.number().int().min(140, 'Height must be 140–199 cm.').max(199, 'Height must be 140–199 cm.'),
  desc: z.string().trim().max(255).optional().default(''),
})
export type CharacterCreateInput = z.infer<typeof characterCreateSchema>


/* ── Account settings ────────────────────────────────────────────── */
export const passwordChangeSchema = z
  .object({
    current_password: z.string().min(1, 'All fields are required.'),
    new_password: z.string().min(8, 'Password must be at least 8 characters.'),
    confirm_password: z.string().min(1, 'All fields are required.'),
  })
  .refine(d => d.new_password === d.confirm_password, {
    message: 'New passwords do not match.',
    path: ['confirm_password'],
  })

export const emailChangeSchema = z.object({
  email: z.email('Invalid email address.').transform(e => e.trim().toLowerCase()),
  password: z.string().min(1, 'All fields are required.'),
})

/* ── Helper: flatten the first error message from a safeParse result ─ */
export function firstError(error: z.ZodError): string {
  return error.issues[0]?.message ?? 'Invalid input.'
}

import { redirect } from 'next/navigation'
/** Old field-specific guide URLs now lead to the configurable general firm guide. */
export default function FirmGuidePage() { redirect('/guides/firms') }


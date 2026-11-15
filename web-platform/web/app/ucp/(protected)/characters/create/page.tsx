import { redirect } from 'next/navigation'
import { checkCharacterLimit } from './actions'
import CreateCharacterForm from './CreateCharacterForm'

export default async function CreateCharacterPage() {
  const atLimit = await checkCharacterLimit()
  if (atLimit) redirect('/ucp/characters')
  return <CreateCharacterForm />
}

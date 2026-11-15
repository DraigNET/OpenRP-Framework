import { requireFactionCharacter } from '@/lib/dal'

export default async function FactionSettingsPage({ params }: PageProps<'/ucp/faction/[id]/settings'>) {
  const { id } = await params
  await requireFactionCharacter(Number(id))

  return (
    <div className="ucp-card">
      <h3>Settings</h3>
      <p>Coming soon.</p>
    </div>
  )
}

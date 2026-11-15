/** Public website settings. Safe to import in client components: never put secrets here.
 * Leave optional links and the server address empty until your community is ready.
 * Use a hostname or IP followed by a port for serverAddress (for example localhost:7777).
 */
export const siteConfig = {
  name: 'OpenRP Framework',
  shortName: 'ORP Framework',
  description: 'A new roleplay community in San Andreas, powered by OpenRP Framework for open.mp.',
  tagline: 'Your next story starts here.',
  siteUrl: '', // Set the public HTTPS origin to enable canonical and absolute social URLs.
  serverAddress: '',
  discordUrl: '',
  forumUrl: '',
  supportEmail: '',
  donationUrl: '',
  logo: '/favicon.png',
  heroImage: '/img/san-andreas-dashboard.png',
  about: 'Make a character. Find your people. Build a life in San Andreas. From your first job to your own business, the next chapter is yours to write.',
  rules: [] as { title: string; body: string }[],
  terms: [] as { title: string; body: string }[],
  privacy: [] as { title: string; body: string }[],
  updates: [] as { title: string; date: string; body: string }[], // Dates: YYYY-MM-DD.
}


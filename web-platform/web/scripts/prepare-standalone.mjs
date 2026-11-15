import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

/** Next's standalone output needs static assets alongside server.js for non-Docker installs. */
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const standalone = path.join(root, '.next', 'standalone')
if (!fs.existsSync(path.join(standalone, 'server.js'))) throw new Error('Run the Next.js build before preparing standalone assets.')
for (const [source, relative] of [['public', 'public'], ['.next/static', '.next/static']]) {
  const destination = path.resolve(standalone, relative)
  if (!destination.startsWith(standalone + path.sep)) throw new Error('Invalid standalone asset destination')
  fs.rmSync(destination, { recursive: true, force: true })
  fs.cpSync(path.join(root, source), destination, { recursive: true })
}
console.log('Prepared standalone public assets and Next.js static files.')

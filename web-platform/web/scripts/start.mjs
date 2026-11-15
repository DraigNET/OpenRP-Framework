import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

/** Start the standalone server with local configuration; hosted environments can inject variables directly. */
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const localEnv = path.join(root, '.env.local')
if (fs.existsSync(localEnv)) process.loadEnvFile(localEnv)
const args = process.argv.slice(2)
const value = name => { const i = args.indexOf(name); return i < 0 ? undefined : args[i + 1] }
process.env.HOSTNAME = value('--hostname') || process.env.WEB_BIND || '127.0.0.1'
process.env.PORT = value('--port') || process.env.PORT || '3000'
const server = path.join(root, '.next/standalone/server.js')
if (!fs.existsSync(server)) throw new Error('Build the website with npm run build first.')
await import(pathToFileURL(server).href)

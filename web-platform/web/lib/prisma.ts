import { PrismaMariaDb } from '@prisma/adapter-mariadb'
import { PrismaClient } from '@prisma/client'

function createPrismaClient() {
  const url = new URL(process.env.DATABASE_URL!)
  const adapter = new PrismaMariaDb({
    host: url.hostname,
    port: url.port ? Number(url.port) : 3306,
    user: decodeURIComponent(url.username),
    password: decodeURIComponent(url.password),
    database: url.pathname.slice(1),
    connectionLimit: 5, // keep headroom for the old PHP site running in parallel
  })
  return new PrismaClient({ adapter })
}

// Singleton — prevents exhausting DB connection limit during hot reloads.
const globalForPrisma = global as unknown as { prisma?: PrismaClient }

// Lazy proxy: the real client (and the DATABASE_URL read) is created on first
// use, not at import. This lets `next build` import route modules without a
// database — connections only happen when a query actually runs at runtime.
function getClient(): PrismaClient {
  if (!globalForPrisma.prisma) {
    globalForPrisma.prisma = createPrismaClient()
  }
  return globalForPrisma.prisma
}

export const prisma: PrismaClient = new Proxy({} as PrismaClient, {
  get(_target, prop) {
    const client = getClient()
    const value = Reflect.get(client, prop, client)
    return typeof value === 'function' ? value.bind(client) : value
  },
})

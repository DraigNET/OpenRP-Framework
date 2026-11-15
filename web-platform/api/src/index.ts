import Fastify from 'fastify'
import cors from '@fastify/cors'

// Base API service. Add authenticated framework endpoints here as needed.
const fastify = Fastify({ logger: true })
await fastify.register(cors, {
  origin: process.env.WEB_URL ?? 'http://localhost:3000',
  credentials: true,
})

fastify.get('/health', async () => ({ status: 'ok' }))

try {
  await fastify.listen({ port: Number(process.env.PORT ?? 3001), host: '0.0.0.0' })
} catch (err) {
  fastify.log.error(err)
  process.exit(1)
}

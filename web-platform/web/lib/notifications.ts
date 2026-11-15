import { prisma } from '@/lib/prisma'

/**
 * Queue a bell notification for an account. Never throws: a failed notification must not
 * break the action that triggered it (e.g. approving a career application).
 * The gamemode writes the same table via Notify_Character() in player/notifications.pwn.
 */
export async function notifyAccount(
  accountId: number,
  type: string,
  title: string,
  body = '',
  link: string | null = null,
): Promise<void> {
  try {
    await prisma.notification.create({
      data: {
        account_id: accountId,
        type: type.slice(0, 32),
        title: title.slice(0, 96),
        body: body.slice(0, 255),
        link,
        created_at: Math.floor(Date.now() / 1000),
      },
    })
  } catch (err) {
    console.error('[notifications] failed to queue notification', err)
  }
}

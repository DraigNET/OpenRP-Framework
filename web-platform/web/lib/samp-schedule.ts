// Module-level singleton — lives for the lifetime of the Next.js Node process.
// Stores the scheduled fire timestamp and the timeout handle.

let timer: ReturnType<typeof setTimeout> | null = null
let fireAt: number | null = null  // Unix ms

export function getScheduledFireAt(): number | null {
  return fireAt
}

export function setSchedule(inSeconds: number, onFire: () => void) {
  cancelSchedule()
  fireAt = Date.now() + inSeconds * 1000
  timer = setTimeout(() => {
    fireAt = null
    timer = null
    onFire()
  }, inSeconds * 1000)
}

export function cancelSchedule() {
  if (timer) { clearTimeout(timer); timer = null }
  fireAt = null
}

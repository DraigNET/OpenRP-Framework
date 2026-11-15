import { NextResponse } from 'next/server'

// The Dispatch desktop app calls these routes cross-origin (Tauri webview).
// Reflect the request origin + allow credentials so it works regardless of the
// client's credentials mode.
export function voiceCors(req: Request): Record<string, string> {
  return {
    'Access-Control-Allow-Origin': req.headers.get('origin') ?? '*',
    'Access-Control-Allow-Credentials': 'true',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-voice-dev-key',
    'Vary': 'Origin',
  }
}

export function voiceJson(req: Request, data: unknown, status = 200) {
  return NextResponse.json(data, { status, headers: voiceCors(req) })
}

export function voicePreflight(req: Request) {
  return new NextResponse(null, { status: 204, headers: voiceCors(req) })
}

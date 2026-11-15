import ScreenshotTool from './ScreenshotTool'

export default function ScreenshotsPage() {
  return (
    <>
      <div className="ucp-card" style={{ marginBottom: 14 }}>
        <h2>Screenshot Overlay</h2>
        <p className="ucp-muted">
          Upload a screenshot, crop and zoom, apply filters, and overlay parsed chat text. Everything runs in your browser — nothing is uploaded.
        </p>
      </div>
      <ScreenshotTool />
    </>
  )
}

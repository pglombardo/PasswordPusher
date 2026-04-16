import { formatBytes } from './format_helpers'
import { setProgressBarProgress } from './progress_bar_helpers'

const DEFAULT_TUS_ROW_TEMPLATE_HTML = `
  <li class="list-group-item list-group-item-primary small tus-upload-row d-flex flex-wrap align-items-center gap-2">
    <span class="badge bg-info text-nowrap">Resumable</span>
    <span class="tus-row-name text-truncate small" style="min-width: 6em"></span>
    <div class="progress flex-grow-1 tus-row-progress-wrap" style="height: 1.5rem; min-width: 80px">
      <div class="progress-bar progress-bar-striped progress-bar-animated tus-row-progress-bar" role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100" style="width: 0%"></div>
    </div>
    <span class="tus-row-size text-muted small text-nowrap" aria-hidden="true"></span>
    <button type="button" class="btn btn-sm btn-outline-secondary d-none tus-row-pause" aria-label="Pause upload" title="Pause"><span class="bi bi-pause-fill"></span></button>
    <button type="button" class="btn btn-sm btn-outline-success d-none tus-row-resume" aria-label="Resume upload" title="Resume"><span class="bi bi-play-fill"></span></button>
  </li>
`

export function cloneTusUploadRow(tusTpl, id, file) {
  let rowNode
  if (tusTpl) {
    rowNode = tusTpl.content.cloneNode(true)
  } else {
    const temp = document.createElement('template')
    temp.innerHTML = DEFAULT_TUS_ROW_TEMPLATE_HTML.trim()
    rowNode = temp.content.cloneNode(true)
  }

  const li = rowNode.querySelector('li')
  li.id = `progress-${id}`
  rowNode.querySelector('.tus-row-name').textContent = file.name

  const progressBar =
    rowNode.querySelector('.tus-row-progress-bar') || rowNode.querySelector('[role="progressbar"]')
  progressBar.id = `tus-upload-${id}`
  progressBar.setAttribute('aria-label', file.name)

  const pauseBtn = rowNode.querySelector('.tus-row-pause')
  const resumeBtn = rowNode.querySelector('.tus-row-resume')
  return { rowNode, li, progressBar, pauseBtn, resumeBtn }
}

export function setTusProgressDetails(progressBar, bytesUploaded, bytesTotal, finalizingLabel) {
  if (!progressBar) return
  const pct = bytesTotal > 0 ? Math.round((bytesUploaded / bytesTotal) * 100) : 0
  setProgressBarProgress(progressBar, pct)
  const row = progressBar.closest('li')
  const sizeEl = row?.querySelector('.tus-row-size')
  if (!sizeEl) return
  if (bytesTotal > 0 && bytesUploaded >= bytesTotal) {
    setTusFinalizing(row, sizeEl, finalizingLabel)
  } else {
    sizeEl.textContent = `${formatBytes(bytesUploaded)} of ${formatBytes(bytesTotal)}`
  }
}

export function setTusFinalizing(row, sizeEl, finalizingLabel) {
  if (row?.dataset.tusFinalizing === 'true') return
  row.dataset.tusFinalizing = 'true'
  const label = finalizingLabel || 'Finalizing…'
  sizeEl.textContent = ''
  sizeEl.classList.add('d-flex', 'align-items-center', 'gap-1')
  sizeEl.appendChild(document.createTextNode(label))
  const spinner = document.createElement('span')
  spinner.className = 'spinner-border spinner-border-sm'
  spinner.setAttribute('role', 'status')
  spinner.setAttribute('aria-hidden', 'true')
  sizeEl.appendChild(spinner)
  const bar = row.querySelector('.tus-row-progress-bar, [role="progressbar"]')
  if (bar) bar.setAttribute('aria-label', label)
}

export function parseTusUploadIdFromLocationHeader(location) {
  if (!location) return null
  try {
    const pathname = new URL(location, window.location.origin).pathname
    const parts = pathname.split('/').filter(Boolean)
    const idx = parts.lastIndexOf('uploads')
    if (idx >= 0 && parts[idx + 1]) return parts[idx + 1]
  } catch (error) {
    console.error('Error parsing TUS upload ID from location header:', error)
  }
  return null
}

export function cancelTusUploadOnServer(uploadUrl) {
  if (!uploadUrl) return
  const url = uploadUrl.startsWith('http') ? uploadUrl : new URL(uploadUrl, window.location.origin).href
  fetch(url, { method: 'DELETE', credentials: 'same-origin' }).catch(() => {})
}

export function signedIdFromTusSuccessPayload(payload) {
  const res = payload?.lastResponse
  return res?.getHeader?.('X-Signed-Id') ?? res?.getHeader?.('x-signed-id') ?? null
}

export function setProgressBarProgress(el, percent) {
  if (!el) return
  el.setAttribute('aria-valuenow', String(percent))
  el.style.width = percent + '%'
}

export function setProgressBarError(el, message) {
  if (!el) return
  el.classList.add('bg-danger')
  const msg = message || 'Upload failed'
  el.setAttribute('aria-label', msg)
  const row = el.closest('li')
  if (row) {
    let errEl = row.querySelector('.upload-error-text')
    if (!errEl) {
      errEl = document.createElement('span')
      errEl.className = 'upload-error-text text-danger small d-block mt-1'
      row.appendChild(errEl)
    }
    errEl.textContent = msg
    errEl.setAttribute('role', 'alert')
  }
}

export function setProgressBarComplete(el) {
  if (!el) return
  el.setAttribute('aria-label', 'Complete')
}

const ClipboardCopyHook = {
  mounted() {
    let { text } = this.el.dataset
    this.el.addEventListener('click', (ev) => {
      ev.preventDefault()
      navigator.clipboard.writeText(text)
    })
  },
}

export default ClipboardCopyHook

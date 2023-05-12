const ClipboardCopyHook = {
  mounted() {
    let { to } = this.el.dataset
    this.el.addEventListener('click', (ev) => {
      ev.preventDefault()
      let text = document.querySelector(to).value
      navigator.clipboard.writeText(text)
    })
  },
}

export default ClipboardCopyHook

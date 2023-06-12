const TrixEditorHook = {
  mounted() {
    const editor_el = document.querySelector("trix-editor")

    editor_el.editor.element.addEventListener("trix-change", (e) => {
      this.el.dispatchEvent(new Event("change", { bubbles: true }))
    })
  },
}

export default TrixEditorHook

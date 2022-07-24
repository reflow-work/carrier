const ReportFormHook = {
  mounted() {
    const sampleButton = this.el.querySelector('button[name="sample"]')
    const analyzeButton = this.el.querySelector('button[name="analyze"]')

    sampleButton.addEventListener('click', () => {
      this.pushEvent("sample", this.formData())
    })
    analyzeButton.addEventListener('click', () => {
      this.pushEvent("analyze", this.formData())
    })
  },
  formData() {
    const formData = new FormData(this.el)

    let object = {}

    for (const [key, value] of formData.entries()) {
      object[key] = value
    }

    return object
  }
}

export default ReportFormHook

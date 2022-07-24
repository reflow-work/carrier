const ReportFormHook = {
  mounted() {
    const testButton = this.el.querySelector('button[name="test"]')
    const analyzeButton = this.el.querySelector('button[name="analyze"]')

    testButton.addEventListener('click', () => {
      this.pushEvent("test", this.formData())
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

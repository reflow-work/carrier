const SlackHook = {
  mounted() {
    const that = this
    this.handleEvent("select_slack_channel", (details) => {
      const id = details.id
      const label = details.label
      const label_input_elem = document.getElementById(details.label_input_id)
      const id_input_elem = document.getElementById(details.id_input_id)
      id_input_elem.value = id
      label_input_elem.value = `#${label}`
      that.pushEvent("validate_report", {})
    })
  }
}

export default SlackHook

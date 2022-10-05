import Smartlook from 'smartlook-client'

const SmartlookHook = {
  mounted() {
    this.handleEvent("smartlook_identify", ({ orgId, userId }) => {
      Smartlook.identify(`${orgId}-${userId}`)
    })
    this.handleEvent("smartlook_anonymize", (_args) => {
      console.log("anonymize called")
      Smartlook.anonymize()
    })
  }
}

export default SmartlookHook

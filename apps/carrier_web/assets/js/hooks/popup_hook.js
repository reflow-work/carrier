const PopupHook = {
  mounted() {
    const popupUrl = this.el.dataset.popupUrl
    const callbackEvent = this.el.dataset.callbackEvent

    this.callbackEventListener = (e) => {
      this.pushEvent(callbackEvent, e.detail)
    }

    document.addEventListener("popup_closed", this.callbackEventListener)
    
    this.el.addEventListener("open_popup", (e) => {
      const windowParams = 'toolbar=no,menubar=no,width=600,height=700,top=100,left=100'
      
      window.open(popupUrl, "popup", windowParams)
    })
  },
  destroyed() {
    document.removeEventListener("popup_closed", this.callbackEventListener)
  }
}

export default PopupHook

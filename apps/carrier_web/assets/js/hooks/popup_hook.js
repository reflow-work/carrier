const PopupHook = {
  mounted() {
    this.el.addEventListener("open-popup", (e) => {
      const url = e.detail.url
      
      const windowParams = 'toolbar=no,menubar=no,width=600,height=700,top=100,left=100'
      
      window.open(url, "popup", windowParams)
    })
  },
}

export default PopupHook

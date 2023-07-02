const GoogleSignInHook = {
  mounted() {
    google.accounts.id.initialize(document.querySelector("#google_signin_info").dataset)
    google.accounts.id.renderButton(this.el, this.el.dataset)
  }
}

export default GoogleSignInHook

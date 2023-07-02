import ChartHook from './chart_hook'
import ClipboardCopy from './clipboard_copy_hook'
import SmartlookHook from './smartlook_hook'
import TrixEditorHook from './trix_editor_hook'
import PopupHook from './popup_hook'
import GoogleSignInHook from './google_signin'

const Hooks = {
  Chart: ChartHook,
  ClipboardCopy: ClipboardCopy,
  Smartlook: SmartlookHook,
  TrixEditor: TrixEditorHook,
  Popup: PopupHook,
  GoogleSignIn: GoogleSignInHook,
}

export default Hooks

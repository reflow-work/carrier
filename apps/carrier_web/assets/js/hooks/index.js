import ChartHook from './chart_hook'
import SmartlookHook from './smartlook_hook'
import SlackHook from './slack_hook'

const Hooks = {
  Slack: SlackHook,
  Chart: ChartHook,
  Smartlook: SmartlookHook,
}

export default Hooks

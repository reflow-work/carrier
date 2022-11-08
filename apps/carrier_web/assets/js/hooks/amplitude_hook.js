import { logEvent } from '@amplitude/analytics-browser'

const AmplitudeHook = {
  mounted() {
    this.handleEvent("amplitude_log_event", ({ eventName, eventProperties }) => {
      logEvent(eventName, eventProperties)
    })
  }
}

export default AmplitudeHook

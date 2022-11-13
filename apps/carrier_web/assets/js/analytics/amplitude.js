import { init, track } from '@amplitude/analytics-browser'

export function initAmplitude() {
  init("9c77fc06bfcc14223518ab4a3979e459")

  window.addEventListener("phx:log-event", ({ detail }) => {
    const {name, properties} = detail

    track(name, properties)
  })
}

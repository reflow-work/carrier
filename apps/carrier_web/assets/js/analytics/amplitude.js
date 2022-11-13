import { init as initClient, track } from '@amplitude/analytics-browser'

export function init(userId) {
  initClient("9c77fc06bfcc14223518ab4a3979e459", userId, {minIdLength: 1})

  window.addEventListener("phx:analytics-log-event", ({ detail }) => {
    const { name, properties } = detail

    track(name, properties)
  })
}

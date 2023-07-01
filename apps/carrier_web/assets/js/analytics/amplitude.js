import * as amplitude from '@amplitude/analytics-browser';

export class Amplitude {
  #initialized = false

  init(userId) {
    if (this.#initialized) return

    amplitude.init(
      "9c77fc06bfcc14223518ab4a3979e459",
      userId,
      {
        minIdLength: 1,
        defaultTracking: {
          pageViews: true,
          sessions: false
        },
      }
    )

    window.addEventListener("phx:analytics-log-event", ({ detail }) => {
      const { name, properties } = detail

      amplitude.track(name, properties)
    })

    this.#initialized = true
  }
}

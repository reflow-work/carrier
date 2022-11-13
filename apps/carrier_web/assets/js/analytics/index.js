import { Amplitude } from './amplitude'

const amplitude = new Amplitude()

window.addEventListener("phx:analytics-init", ({ detail }) => {
  const { user_id: userId } = detail

  amplitude.init(userId)
})

import { init as initAmplitude } from './amplitude'

window.addEventListener("phx:analytics-init", ({ detail }) => {
  const { user_id: userId } = detail

  initAmplitude(userId)
})

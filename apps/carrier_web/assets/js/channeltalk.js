window.addEventListener("phx:channeltalk-boot", ({ detail }) => {
  const { user_id: userId } = detail

  window.ChannelIO('boot', {
    "pluginKey": "e6d64b9d-7a09-481e-9a50-de268b6bfb79",
    "memberId": userId
  });

  window.addEventListener("phx:channeltalk-open", () => {
    window.ChannelIO('showMessenger')
  })
})

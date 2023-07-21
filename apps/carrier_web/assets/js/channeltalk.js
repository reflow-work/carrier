window.addEventListener("phx:channeltalk-boot", ({ detail }) => {
  window.ChannelIO('boot', {
    "pluginKey": "e6d64b9d-7a09-481e-9a50-de268b6bfb79",
    ...detail
  });

  window.addEventListener("phx:channeltalk-open", () => {
    window.ChannelIO('showMessenger')
  })
})

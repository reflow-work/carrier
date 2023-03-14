let tossPayments 

window.addEventListener("phx:toss-payments-init", ({ detail }) => {
  const { client_key: clientKey } = detail

  tossPayments = TossPayments(clientKey)
})

window.addEventListener("phx:toss-payments-request", ({ detail }) => {
  const { customer_key: customerKey, success_url: successUrl, fail_url: failUrl } = detail

  tossPayments.requestBillingAuth('카드', {
    customerKey,
    successUrl,
    failUrl,
  })
  .catch(function (error) {
    if (error.code === 'USER_CANCEL') {
      console.error('결제 고객이 결제창을 닫았을 때 에러 처리')
    } else if (error.code === 'INVALID_CARD_COMPANY') {
      console.error('유효하지 않은 카드 코드에 대한 에러 처리')
    }
  })
})

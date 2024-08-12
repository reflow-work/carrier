defmodule CarrierWeb.App.InvoiceController do
  use CarrierWeb, :controller
  use Carrier.Payments

  def show(conn, %{"payment_id" => payment_id}) do
    with {:ok, payment} <- Payments.fetch_payment(payment_id),
         payment = payment |> Carrier.Repo.preload([:subscription, :credit_card]),
         {:ok, plan} <- Carrier.Billing.Super.fetch_plan(payment.subscription.plan_id) do
      conn
      |> render(:show, payment: %{payment | subscription: %{payment.subscription | plan: plan}})
    else
      {:error, _} ->
        conn
        |> put_flash(:error, "Payment not found")
        |> redirect(to: "/")
    end
  end
end

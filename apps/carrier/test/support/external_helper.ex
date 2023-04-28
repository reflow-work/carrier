defmodule Carrier.ExternalHelper do
  import ExUnit.Assertions, only: [assert: 1]
  import Doumi.CaseHelper

  def expect(bypass, method, path, {:json, body}, opts \\ [])
      when is_atom(method) and is_binary(path) and (is_map(body) or is_list(body)) do
    status = opts |> Keyword.get(:status, 200)
    validate = opts |> Keyword.get(:validate, fn _params, _body -> true end)
    once = opts |> Keyword.get(:once, false)

    expect_fun =
      case once do
        true -> &Bypass.expect_once/4
        false -> &Bypass.expect/4
      end

    expect_fun.(bypass, convert_method(method), path, fn conn ->
      {:ok, req_body, conn} = Plug.Conn.read_body(conn)
      validate.(conn.params, Jason.decode!(req_body))

      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.resp(status, Jason.encode!(body))
    end)
  end

  defp convert_method(method) do
    case method do
      :get -> "GET"
      :post -> "POST"
      :put -> "PUT"
      :delete -> "DELETE"
    end
  end

  defmodule TossPayments do
    def prepare_issue_billing_auth(auth_key, customer_key) do
      success_resp =
        Carrier.Fixture.json("toss_payments/issue_billing_auth.success.json")
        |> Map.put("customerKey", customer_key)

      Bypass.open(port: 4101)
      |> Carrier.ExternalHelper.expect(
        :post,
        "/v1/billing/authorizations/issue",
        {:json, success_resp},
        validate: fn _params, body ->
          assert body == %{"authKey" => auth_key, "customerKey" => customer_key}
        end
      )

      success_resp
    end

    def prepare_bill(
          %{
            billing_key: billing_key,
            amount: amount,
            order_name: order_name,
            customer_email: customer_email,
            customer_name: customer_name
          },
          opts \\ []
        ) do
      fail = opts |> Keyword.get(:fail, false)
      status = if fail, do: 400, else: 200

      resp =
        case fail do
          false -> Carrier.Fixture.json("toss_payments/bill.success.json")
          true -> Carrier.Fixture.json("toss_payments/fail.json")
        end

      Bypass.open(port: 4101)
      |> Carrier.ExternalHelper.expect(
        :post,
        "/v1/billing/#{billing_key}",
        {:json, resp},
        validate: fn _params, body ->
          assert %{
                   "amount" => body_amount,
                   "orderName" => ^order_name,
                   "customerEmail" => ^customer_email,
                   "customerName" => ^customer_name
                 } = body

          assert same_values?(body_amount, amount)
        end,
        status: status
      )

      resp
    end
  end

  defmodule TableauAPI do
    def prepare_signin() do
      success_resp = Carrier.Fixture.json("tableau_api/signin.user.success.json")

      Bypass.open(port: 4102)
      |> Carrier.ExternalHelper.expect(
        :post,
        "/api/3.18/auth/signin",
        {:json, success_resp}
      )

      success_resp
    end
  end
end

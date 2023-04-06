defmodule Carrier.ExternalHelper do
  def expect_once(bypass, method, path, {:json, body}, opts \\ [])
      when is_atom(method) and is_binary(path) and (is_map(body) or is_list(body)) do
    status = opts |> Keyword.get(:status, 200)
    validate = opts |> Keyword.get(:validate, fn _params, _body -> true end)

    Bypass.expect_once(bypass, convert_method(method), path, fn conn ->
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
end

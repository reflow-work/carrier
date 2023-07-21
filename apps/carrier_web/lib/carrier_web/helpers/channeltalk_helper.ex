defmodule CarrierWeb.ChanneltalkHelper do
  import Phoenix.LiveView, only: [push_event: 3]
  alias Phoenix.LiveView.JS
  alias Carrier.Obfuscatable

  def boot_channeltalk(socket) do
    detail =
      case socket.assigns[:user] do
        nil ->
          %{}

        %{org: org} = user ->
          obfuscated_user_id = Obfuscatable.obfuscate(user)
          obfuscated_org_id = Obfuscatable.obfuscate(org)

          %{
            "memberId" => obfuscated_user_id,
            "memberHash" => hash(obfuscated_user_id),
            "profile" => %{
              "orgId" => obfuscated_org_id
            }
          }
      end

    socket
    |> push_event("channeltalk-boot", detail)
  end

  def open_channel_talk(socket) do
    socket
    |> push_event("channeltalk-open", %{})
  end

  def js_open_channel_talk(js \\ %JS{}) do
    js
    |> JS.dispatch("phx:channeltalk-open")
  end

  defp hash(value) do
    :crypto.mac(:hmac, :sha256, secret_key() |> Base.decode16!(case: :lower), value)
    |> Base.encode16(case: :lower)
  end

  # To enable security option for channeltalk, use right secret key
  # https://developers.channel.io/docs/member-hash
  defp secret_key() do
    # It's a fake key
    "4629de5def93d6a2abea6afa9bd5476d9c6cbc04223f9a2f7e517b535dde3e25"
  end
end

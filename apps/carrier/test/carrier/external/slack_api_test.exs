defmodule Carrier.External.SlackAPITest do
  use ExUnit.Case
  alias Carrier.ExternalHelper
  alias Carrier.External.SlackAPI

  setup do
    bypass = Bypass.open(port: 4103)

    %{bypass: bypass}
  end

  describe "list_conversations/1" do
    @sucess_resp Carrier.Fixture.json("slack_api/conversations.list.success.json")

    test "with valid params", %{bypass: bypass} do
      params = %{limit: 2, scope: "channels:read,groups:read,im:read", cursor: "cursor"}
      token = "token"

      ExternalHelper.expect(
        bypass,
        :get,
        "/api/conversations.list",
        {:json, @sucess_resp},
        validate: fn conn, _body ->
          assert ["Bearer token"] = conn |> Plug.Conn.get_req_header("authorization")

          assert conn.params == %{
                   "cursor" => "cursor",
                   "exclude_archived" => "true",
                   "limit" => "2",
                   "types" => "public_channel,private_channel,im"
                 }
        end
      )

      assert {:ok, %{channels: [channel0, channel1], pagination: pagination}} =
               SlackAPI.list_conversations(params, token)

      assert channel0.id == "C03KTBEU3ST"
      assert channel0.name == "1-제품개발"
      assert channel0.type == :public_channel
      assert channel1.id == "C056VFU2CE4"
      assert channel1.name == "private"
      assert channel1.type == :private_channel

      assert pagination.next_cursor == "dGVhbTpDMDNMMFVMRlVEVQ=="
    end

    @fail_resp Carrier.Fixture.json("slack_api/fail.json")

    test "with invalid token", %{bypass: bypass} do
      params = %{limit: 2, cursor: "cursor"}
      token = "token"

      ExternalHelper.expect(
        bypass,
        :get,
        "/api/conversations.list",
        {:json, @fail_resp}
      )

      assert {:error, "invalid_auth"} = SlackAPI.list_conversations(params, token)
    end
  end
end

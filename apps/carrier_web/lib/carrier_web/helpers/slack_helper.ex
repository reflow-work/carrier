defmodule CarrierWeb.Helpers.SlackHelper do
  use CarrierWeb, :verified_routes

  def get_redirect_uri(nil, popup) do
    url(~p"/app/data-targets/callback/slack?popup=#{boolean_param(popup)}")
  end

  def get_redirect_uri(data_target_id, popup) do
    url(
      ~p"/app/data-targets/callback/slack?data_target_id=#{data_target_id}&popup=#{boolean_param(popup)}"
    )
  end

  defp boolean_param(param) do
    case param do
      true -> true
      "true" -> true
      _ -> false
    end
  end
end

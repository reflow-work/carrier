defmodule CarrierWeb.OnboardingHook do
  use CarrierWeb, :live_hook
  use Carrier.Accounts
  require Logger

  def on_mount(:default, _params, _session, socket) do
    case load_org() do
      %Org{} = org ->
        org |> IO.inspect()

        if org.name == "" || org.name == "organization" do
          socket =
            socket
            |> redirect(to: Routes.onboarding_path(socket, :index))

          {:halt, socket}
        else
          {:cont, socket}
        end

      _ ->
        {:cont, socket}
    end
  end

  defp load_org() do
    case Accounts.fetch_org() do
      {:ok, %Org{} = org} -> org
      _ -> nil
    end
  end
end

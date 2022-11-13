defmodule CarrierWeb.OnboardingHook do
  use CarrierWeb, :live_hook
  use Carrier.Accounts
  require Logger

  def on_mount(:default, _params, _session, socket) do
    if socket.assigns.org.name == "organization" do
      socket =
        socket
        |> redirect(to: Routes.onboarding_path(socket, :index))

      {:halt, socket}
    else
      {:cont, socket}
    end
  end
end

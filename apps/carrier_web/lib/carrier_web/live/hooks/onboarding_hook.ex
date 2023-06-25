defmodule CarrierWeb.OnboardingHook do
  use CarrierWeb, :live_hook
  use Carrier.Accounts

  def on_mount(:default, _params, _session, socket) do
    if socket.view != CarrierWeb.App.OnboardingLive && !socket.assigns.org.onboarded do
      socket =
        socket
        |> push_navigate(to: ~p"/app/onboarding")

      {:halt, socket}
    else
      {:cont, socket}
    end
  end
end

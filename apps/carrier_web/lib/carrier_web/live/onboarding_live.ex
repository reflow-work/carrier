defmodule CarrierWeb.OnboardingLive do
  use CarrierWeb, :live_view

  alias Carrier.Accounts
  alias Carrier.Accounts.{Org, User}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("update_onboarding", %{"onboarding" => onboarding_inputs}, socket) do
    %{"position" => position} = onboarding_inputs

    case Accounts.update_user(socket.assigns.user.id, %{position: position}) do
      {:ok, _} ->
        socket =
          socket
          |> push_navigate(to: Routes.integration_new_path(socket, :new))

        {:noreply, socket}

      {:error, _} ->
        socket = socket |> put_flash(:error, "회사 정보 입력에 실패하였습니다. 다시 시도해주세요.")
        {:noreply, socket}
    end
  end
end

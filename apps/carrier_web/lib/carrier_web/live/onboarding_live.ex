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
    %{
      "position" => position,
      "name" => name,
      "industry" => industry,
      "employee_count" => employee_count
    } = onboarding_inputs

    with {:ok, %User{}} <- Accounts.update_user(socket.assigns.user.id, %{position: position}),
         {:ok, %Org{}} <-
           Accounts.update_org(%{
             name: name,
             industry: industry,
             employee_count: employee_count
           }) do
      socket =
        socket
        |> push_navigate(to: Routes.integration_new_path(socket, :new))

      {:noreply, socket}
    else
      {:error, _} ->
        socket = socket |> put_flash(:error, "회사 정보 입력에 실패하였습니다. 다시 시도해주세요.")

        {:noreply, socket}
    end
  end
end

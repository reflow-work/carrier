defmodule CarrierWeb.App.OnboardingLive do
  use CarrierWeb, :live_view
  alias Carrier.Context.Onboarding
  alias Carrier.Accounts.{Org, User}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: false}
  end

  @impl true
  def handle_event("validate_onboarding", %{"onboarding" => onboarding_inputs}, socket) do
    socket =
      socket
      |> assign(:onboarding, onboarding_inputs)

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_onboarding", %{"onboarding" => onboarding_inputs}, socket) do
    %{
      "position" => position,
      "name" => name,
      "industry" => industry,
      "employee_count" => employee_count,
      "agreed_terms_of_service" => agreed_terms_of_service,
      "agreed_privacy_policy" => agreed_privacy_policy
    } = onboarding_inputs

    with :ok <- validate_policy(agreed_terms_of_service, agreed_privacy_policy),
         Onboarding.onboard(%{
           org_id: socket.assigns.org.org_id,
           user_id: socket.assigns.user.id,
           name: name,
           industry: industry,
           employee_count: employee_count,
           position: position
         }) do
      socket =
        socket
        |> push_navigate(to: ~p"/app/reports/new2")

      {:noreply, socket}
    else
      {:error, {:validation_error, message}} ->
        socket =
          socket
          |> put_flash_for(:error, message, timeout: :timer.seconds(3))

        {:noreply, socket}

      {:error, _} ->
        socket =
          socket
          |> put_flash_for(:error, "회사 정보 입력에 실패하였습니다. 다시 시도해주세요.", timeout: :timer.seconds(3))

        {:noreply, socket}
    end
  end

  defp validate_policy(agreed_terms_of_service, agreed_privacy_policy) do
    case {agreed_terms_of_service, agreed_privacy_policy} do
      {"true", "true"} ->
        :ok

      {"false", _} ->
        {:error, {:validation_error, "이용약관에 동의해주세요."}}

      {_, "false"} ->
        {:error, {:validation_error, "개인정보 처리방침에 동의해주세요."}}

      _ ->
        {:error, {:validation_error, "약관에 동의해주세요."}}
    end
  end
end

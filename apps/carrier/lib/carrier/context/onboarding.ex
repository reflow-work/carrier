defmodule Carrier.Context.Onboarding do
  use Carrier.{Accounts, Integrations, Billing}
  alias Carrier.TenantRepo

  def onboard(%{
        org_id: org_id,
        user_id: user_id,
        name: name,
        industry: industry,
        employee_count: employee_count,
        position: position
      }) do
    now = DateTime.utc_now()

    TenantRepo.wrap_transaction(fn ->
      with {:ok, %Org{}} <-
             Accounts.update_org(%{
               name: name,
               industry: industry,
               employee_count: employee_count
             }),
           {:ok, %User{}} <-
             Accounts.update_user(user_id, %{
               position: position,
               agreed_terms_of_service_at: now,
               agreed_privacy_policy_at: now
             }),
           {:ok, _} <- create_trial_subscription(%{org_id: org_id}) do
        {:ok, nil}
      end
    end)
  end

  defp create_trial_subscription(%{org_id: org_id}) do
    start_on = DateTime.utc_now()

    with %Plan{id: plan_id, type: :trial} <- Billing.Super.fetch_trial_plan!(),
         {:ok, %Subscription{} = trial_subscription} <-
           Billing.start_subscription(%{
             org_id: org_id,
             plan_id: plan_id,
             start_on: start_on
           }) do
      {:ok, trial_subscription}
    end
  end
end

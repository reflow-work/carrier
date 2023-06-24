defmodule Carrier.Context.Onboarding do
  use Carrier.Accounts
  alias Carrier.TenantRepo

  def onboard(%{
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
             }) do
        {:ok, nil}
      end
    end)
  end
end

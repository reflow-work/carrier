defmodule Carrier.Context.Onboarding do
  use Carrier.{Accounts, Integrations}
  alias Carrier.TenantRepo
  alias Carrier.Core.Traversable

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
           {:ok, _} <- create_demo_data_sources(%{org_id: org_id}) do
        {:ok, nil}
      end
    end)
  end

  defp create_demo_data_sources(%{org_id: org_id}) do
    TenantRepo.wrap_transaction(fn ->
      [
        %{org_id: org_id, name: "(Demo) Tableau", source: :tableau_demo, conn_info: %{}},
        %{org_id: org_id, name: "(Demo) Relational Database", source: :rdb_demo, conn_info: %{}}
      ]
      |> Enum.map(&Integrations.create_data_source/1)
      |> Traversable.traverse()
    end)
  end
end

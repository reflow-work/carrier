defmodule Carrier.Integrations do
  alias Carrier.Integrations.ConnValidator
  alias Carrier.Integrations.{DataTarget, DataSource, ConnInfo}
  alias Carrier.TenantRepo
  alias Carrier.Tenant

  defmacro __using__([]) do
    quote do
      alias Carrier.Integrations
      alias Carrier.Integrations.ConnValidator
      alias Carrier.Integrations.{DataTarget, DataSource, ConnInfo}
    end
  end

  def create_data_target(%{
        org_id: org_id,
        service_name: service_name,
        conn_info: conn_info_params
      }) do
    conn_info_params = %{
      org_id: org_id,
      name: service_name |> Atom.to_string(),
      source: service_name,
      info: conn_info_params
    }

    TenantRepo.wrap_transaction(fn ->
      with {:ok, %ConnInfo{id: conn_info_id}} <- create_conn_info(conn_info_params, :target),
           {:ok, %DataTarget{} = data_target} <-
             DataTarget.create(%{
               org_id: org_id,
               service_name: service_name,
               conn_info_id: conn_info_id
             })
             |> TenantRepo.insert() do
        {:ok, data_target |> TenantRepo.preload(:conn_info)}
      end
    end)
  end

  def create_data_source(%{
        org_id: org_id,
        name: name,
        source: source,
        conn_info: conn_info_params
      }) do
    conn_info_params = %{
      org_id: org_id,
      name: name,
      source: source,
      info: conn_info_params
    }

    TenantRepo.wrap_transaction(fn ->
      with {:ok, %ConnInfo{id: conn_info_id}} <- create_conn_info(conn_info_params, :source),
           {:ok, %DataSource{} = data_source} <-
             DataSource.create(%{
               org_id: org_id,
               name: name,
               source: source,
               conn_info_id: conn_info_id
             })
             |> TenantRepo.insert() do
        {:ok, data_source |> TenantRepo.preload(:conn_info)}
      end
    end)
  end

  def update_conn_info_of_data_target(data_target_id, %{info: info}) do
    TenantRepo.wrap_transaction(fn ->
      with {:ok, %DataTarget{conn_info: %ConnInfo{} = conn_info} = data_target} <-
             fetch_data_target(data_target_id),
           {:ok, %ConnInfo{} = updated_conn_info} <-
             do_update_info_of_conn_info(conn_info, %{info: info}),
           {:ok, %DataTarget{} = updated_data_target} <-
             do_update_needs_update_of_data_target(data_target, false) do
        {:ok, %DataTarget{updated_data_target | conn_info: updated_conn_info}}
      end
    end)
  end

  def list_data_targets() do
    DataTarget.list()
    |> DataSource.preload_conn_info()
    |> TenantRepo.all()
    |> then(&{:ok, &1})
  end

  def fetch_data_target(data_target_id) do
    DataTarget.fetch(data_target_id)
    |> DataSource.preload_conn_info()
    |> TenantRepo.one()
    |> case do
      %DataTarget{} = data_target ->
        {:ok, data_target}

      nil ->
        {:error,
         {:resource_not_found,
          %{target: DataTarget, conditions: %{data_target_id: data_target_id}}}}
    end
  end

  def list_data_sources() do
    DataSource.list()
    |> DataSource.preload_conn_info()
    |> TenantRepo.all()
    |> then(&{:ok, &1 ++ list_demo_data_sources()})
  end

  def fetch_data_source(data_source_id) do
    DataSource.fetch(data_source_id)
    |> DataSource.preload_conn_info()
    |> TenantRepo.one()
    |> case do
      %DataSource{} = data_source ->
        {:ok, data_source}

      nil ->
        list_demo_data_sources()
        |> Enum.find(&(&1.id == data_source_id))
        |> case do
          nil ->
            {:error,
             {:resource_not_found,
              %{target: DataSource, conditions: %{data_source_id: data_source_id}}}}

          data_source ->
            {:ok, data_source}
        end
    end
  end

  def create_conn_info(%{org_id: org_id, name: name, source: source, info: info}, type) do
    with :ok <- ConnValidator.validate(source, info, type),
         {:ok, %ConnInfo{} = conn_info} <-
           ConnInfo.create(%{org_id: org_id, name: name, source: source, info: info})
           |> TenantRepo.insert() do
      {:ok, conn_info}
    end
  end

  defp do_update_info_of_conn_info(%ConnInfo{} = conn_info, %{info: info}) do
    ConnInfo.update_info(conn_info, %{info: info})
    |> TenantRepo.update()
  end

  defp do_update_needs_update_of_data_target(%DataTarget{} = data_target, needs_update) do
    DataTarget.update_needs_update(data_target, needs_update)
    |> TenantRepo.update()
  end

  defp list_demo_data_sources() do
    org_id = Tenant.get_org_id()

    [
      %DataSource{
        id: 100_000_000_001,
        org_id: org_id,
        source: :tableau,
        name: "(Demo) Tableau",
        demo: true,
        conn_info: %ConnInfo{source: :demo, info: %{}}
      },
      %DataSource{
        id: 100_000_000_002,
        org_id: org_id,
        source: :postgres,
        name: "(Demo) PostgreSQL",
        demo: true,
        conn_info: %ConnInfo{source: :demo, info: %{}}
      }
    ]
  end
end

defmodule Carrier.TenantFactory do
  use ExMachina.Ecto, repo: Carrier.TenantRepo
  alias Carrier.Accounts.Org
  alias Carrier.Secrets.{Integration, DataSource, ConnInfo}
  alias Carrier.Reports.Report

  def org_factory() do
    %Org{
      name: seq(:org_name)
    }
  end

  def integration_factory(attrs) do
    {service_name, attrs} = attrs |> Map.pop(:service_name, Enum.random([:slack]))

    {{org_id, conn_info_id}, attrs} =
      attrs
      |> Map.pop_lazy(:conn_info_id, fn ->
        conn_info = insert(:conn_info, source: service_name)
        {conn_info.org_id, conn_info.id}
      end)

    %Integration{
      org_id: org_id,
      service_name: Enum.random([:slack]),
      conn_info_id: conn_info_id
    }
    |> merge_attributes(attrs)
  end

  def data_source_factory(attrs) do
    {source, attrs} = attrs |> Map.pop(:source, Enum.random([:postgres, :mysql]))

    {{org_id, conn_info}, attrs} =
      attrs
      |> Map.pop_lazy(:conn_info, fn ->
        conn_info = insert(:conn_info, source: source)
        {conn_info.org_id, conn_info}
      end)

    %DataSource{
      org_id: org_id,
      name: seq(:data_source_name),
      source: source,
      conn_info: conn_info
    }
    |> merge_attributes(attrs)
  end

  def conn_info_factory(attrs) do
    {org_id, attrs} = attrs |> Map.pop_lazy(:org_id, fn -> insert(:org).org_id end)

    %ConnInfo{
      org_id: org_id,
      name: seq(:conn_info_name),
      source: [:postgres, :mysql] |> Enum.random(),
      info: %{}
    }
    |> merge_attributes(attrs)
  end

  def report_factory(attrs) do
    {org_id, attrs} = attrs |> Map.pop_lazy(:org_id, fn -> insert(:org).org_id end)

    %Report{
      org_id: org_id,
      name: seq(:report_name)
    }
    |> merge_attributes(attrs)
  end

  defp seq(name) when is_atom(name) do
    sequence(Atom.to_string(name))
  end

  defp seq(name, formatter) do
    sequence(name, formatter)
  end
end

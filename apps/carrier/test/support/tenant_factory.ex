defmodule Carrier.TenantFactory do
  use ExMachina.Ecto, repo: Carrier.TenantRepo
  alias Carrier.Accounts.Org
  alias Carrier.Secrets.ConnInfo

  def org_factory() do
    %Org{
      name: seq(:org_name)
    }
  end

  def conn_info_factory(attrs) do
    {org_id, attrs} = attrs |> Map.pop_lazy(:org_id, fn -> insert(:org).org_id end)

    %ConnInfo{
      org_id: org_id,
      name: seq(:conn_info_name),
      source: ["postgres", "mysql"] |> Enum.random(),
      info: %{}
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

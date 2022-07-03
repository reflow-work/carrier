defmodule Carrier.Factory do
  use ExMachina.Ecto, repo: Carrier.Repo
  alias Carrier.Accounts.Org

  def org_factory() do
    %Org{
      name: seq(:org_name)
    }
  end

  defp seq(name) when is_atom(name) do
    sequence(Atom.to_string(name))
  end

  defp seq(name, formatter) do
    sequence(name, formatter)
  end
end

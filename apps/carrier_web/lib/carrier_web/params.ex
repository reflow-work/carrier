defmodule CarrierWeb.Params do
  import Ecto.Changeset, only: [apply_changes: 1]
  alias Ecto.Changeset

  defmacro __using__([]) do
    quote do
      alias unquote(__MODULE__)
    end
  end

  def set_action(%Changeset{} = changeset, action) do
    %Changeset{changeset | action: action}
  end

  def to_map(%Changeset{} = changeset) do
    struct = changeset |> apply_changes()

    do_to_map(struct)
  end

  defp do_to_map(%module{} = struct) when is_struct(struct) do
    embeds = module.__schema__(:embeds)

    new_struct =
      embeds
      |> Enum.reduce(struct, fn embed, acc ->
        Map.update!(acc, embed, &do_to_map(&1))
      end)

    new_struct |> Map.from_struct()
  end
end

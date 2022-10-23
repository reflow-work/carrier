defmodule CarrierWeb.Params do
  alias Ecto.Changeset

  defmacro __using__([]) do
    quote do
      import unquote(__MODULE__)
      import Ecto.Changeset, only: [apply_changes: 1]
    end
  end

  def set_action(%Changeset{} = changeset, action) do
    %Changeset{changeset | action: action}
  end
end

defmodule Carrier.Data.Target.Slack do
  alias Carrier.External.SlackAPI

  defmodule Channel do
    defstruct [:id, :name, :is_private]

    def new(%{"id" => id, "name" => name, "is_private" => is_private}) do
      %__MODULE__{id: id, name: name, is_private: is_private}
    end
  end

  defmodule Pagination do
    defstruct [:next_cursor]

    def new(%{"next_cursor" => next_cursor}) do
      %__MODULE__{next_cursor: next_cursor}
    end
  end
end

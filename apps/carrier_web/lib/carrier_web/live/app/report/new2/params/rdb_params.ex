defmodule CarrierWeb.App.ReportLive.New2.RDBParams do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
  end

  @required []
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
  end
end

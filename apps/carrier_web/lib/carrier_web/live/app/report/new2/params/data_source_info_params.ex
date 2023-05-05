defmodule CarrierWeb.App.ReportLive.New2.DataSourceInfoParams do
  use Ecto.Schema
  import Ecto.Changeset
  alias CarrierWeb.App.ReportLive.New2.TableauDetailsParams

  @primary_key false
  embedded_schema do
    field :data_source_id, :id
    field :source, Ecto.Enum, values: [:tableau]
    field :details, :map
  end

  @required [:data_source_id, :source, :details]
  def changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> validate_details()
  end

  defp validate_details(%Ecto.Changeset{changes: %{source: source}, valid?: true} = changeset) do
    changeset
    |> validate_change(:details, fn :details, details ->
      details_module =
        case source do
          :tableau -> TableauDetailsParams
        end

      details_changeset = details_module.changeset(struct(details_module), details)

      case details_changeset.valid? do
        true -> []
        false -> details_changeset.errors
      end
    end)
  end

  defp validate_details(changeset), do: changeset
end

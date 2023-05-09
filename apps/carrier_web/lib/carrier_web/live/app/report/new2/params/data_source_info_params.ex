defmodule CarrierWeb.App.ReportLive.New2.DataSourceInfoParams do
  use Ecto.Schema
  import Ecto.Changeset
  alias CarrierWeb.App.ReportLive.New2.TableauParams

  @primary_key false
  embedded_schema do
    field :data_source_id, :id
    field :source, Ecto.Enum, values: [:tableau]
    field :params, :map
  end

  @required [:data_source_id, :source, :params]
  def changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> validate_params()
  end

  defp validate_params(%Ecto.Changeset{changes: %{source: source}, valid?: true} = changeset) do
    changeset
    |> validate_change(:params, fn :params, params ->
      params_module =
        case source do
          :tableau -> TableauParams
        end

      params_changeset = params_module.changeset(struct(params_module), params)

      case params_changeset.valid? do
        true -> []
        false -> params_changeset.errors
      end
    end)
  end

  defp validate_params(changeset), do: changeset
end

defmodule Carrier.Reports.DataTargetInfo do
  use Carrier.Schema
  use Doumi.Phoenix.Params, as: :data_target_info
  alias __MODULE__.SlackDataTargetInfo

  @derive Jason.Encoder
  @primary_key false
  embedded_schema do
    field :data_target_id, :id
    field :target, Ecto.Enum, values: [:slack]
    field :params, :map
  end

  @required [:data_target_id, :target, :params]
  def changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> validate_params()
  end

  defp validate_params(%Ecto.Changeset{changes: %{target: target}, valid?: true} = changeset) do
    changeset
    |> validate_change(:params, fn :params, params ->
      params_module = params_module(target)
      params_changeset = params_module.changeset(struct(params_module), params)

      case params_changeset.valid? do
        true -> []
        false -> params_changeset.errors
      end
    end)
  end

  defp validate_params(changeset), do: changeset

  def to_string(%__MODULE__{target: target, params: params}) do
    params_module(target).to_string(params)
  end

  def load_params(%__MODULE__{} = struct) do
    %__MODULE__{struct | params: to_params(struct)}
  end

  defp to_params(%__MODULE__{target: target, params: params}) do
    params_module(target).to_params(params)
  end

  defp params_module(target) do
    case target do
      :slack -> SlackDataTargetInfo
    end
  end
end

defmodule Carrier.PrivLoader do
  def read(relative_path) do
    relative_path |> path() |> File.read!()
  end

  def json(relative_path) do
    relative_path |> read() |> Jason.decode!()
  end

  defp path(relative_path) do
    "#{:code.priv_dir(:carrier)}/#{relative_path}"
  end
end

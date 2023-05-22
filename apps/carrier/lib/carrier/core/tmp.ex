defmodule Carrier.Core.Tmp do
  def mkdir() do
    dir = Path.join(System.tmp_dir!(), unique_name())

    :ok = File.mkdir_p(dir)

    dir
  end

  def tmp_path("." <> _ = ext) do
    Path.join(mkdir(), unique_name() <> ext)
  end

  defp unique_name() do
    "#{:os.system_time(:millisecond)}-#{:erlang.unique_integer([:positive])}"
  end
end

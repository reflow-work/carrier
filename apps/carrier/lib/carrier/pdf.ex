defmodule Carrier.PDF do
  alias Carrier.PythonPool
  alias Carrier.Core.Tmp

  def merge(file_paths) do
    output_path = Tmp.tmp_path(".pdf")

    PythonPool.command(:pdf, :merge, [file_paths, output_path])

    output_path
  end
end

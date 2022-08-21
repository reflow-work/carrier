defmodule CarrierWeb.Components.Icon do
  use Phoenix.Component

  @icon_paths "icons/*"
  paths = Path.wildcard(@icon_paths)
  paths_hash = :erlang.md5(paths)

  for path <- paths do
    @external_resource path
  end

  for path <- paths do
    name = Path.basename(path, ".svg") |> String.replace("-", "_")
    "<svg " <> remains = File.read!(path)
    content = "<svg " <> " {assigns} " <> remains

    def unquote(String.to_atom(name))(assigns) do
      sigil_H(<<unquote(content)>>, [])
    end
  end

  def __mix_recompile__?() do
    unquote(paths) |> :erlang.md5() != unquote(paths_hash)
  end
end

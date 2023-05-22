defmodule Carrier.Core.TmpTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.Tmp

  test "mkdir/0" do
    assert dir0 = Tmp.mkdir()
    assert dir1 = Tmp.mkdir()

    assert File.dir?(dir0) == true
    assert File.dir?(dir1) == true
    assert dir0 != dir1
  end

  test "tmp_path/1" do
    assert path0 = Tmp.tmp_path(".txt")
    assert path1 = Tmp.tmp_path(".txt")

    assert File.exists?(path0) == false
    assert File.exists?(path1) == false

    assert path0 != path1

    dir0 = Path.dirname(path0)
    dir1 = Path.dirname(path1)

    assert File.dir?(dir0) == true
    assert File.dir?(dir1) == true

    assert dir0 != dir1
  end
end

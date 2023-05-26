defmodule Carrier.PythonPool do
  use Doumi.Port.Pool,
    port: {
      Doumi.Port.Python,
      python: "python3",
      python_path: [
        [:code.priv_dir(:carrier), "python"] |> Path.join(),
        [:code.priv_dir(:carrier), "python", "lib"] |> Path.join()
      ]
    }
end

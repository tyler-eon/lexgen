defmodule Lexgen.Xrpc do
  def required_param_names(function) do
    function.input
    |> Enum.filter(fn param -> param.required end)
    |> Enum.map(fn param -> ":#{param.name}" end)
  end

  def param_names(function) do
    function.input
    |> Enum.map(fn param -> ":#{param.name}" end)
  end

  def xrpc_target(%{nsid: nsid, key: "main"}), do: nsid
  def xrpc_target(%{nsid: nsid, key: key}), do: "#{nsid}.#{key}"

  def params_spec(function) do
    spec =
      function.input
      |> Enum.map(fn param -> "#{param.name}: #{param.type}" end)
      |> Enum.join(",\n    ")

    case spec do
      "" -> "%{}"
      _ -> "%{
    #{spec}
  }"
    end
  end
end

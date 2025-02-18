defmodule Lexgen.Structs do
  def specs(struct) do
    struct.fields
    |> Enum.map(fn %{name: field_name, type: field_type} ->
      "#{field_name}: #{field_type}"
    end)
  end

  def fields(struct) do
    struct.fields
    |> Enum.map(fn %{name: field_name, default: default} ->
      "#{field_name}: #{default}"
    end)
  end
end

defmodule Lexgen.Schema do
  @moduledoc """
  Generates code snippets for schema generation of `record` definitions.
  """

  def safe_key(lexicon, "main"), do: lexicon.id

  def safe_key(_lexicon, key), do: key

  def deref_main(lexicon, "main"), do: lexicon.nsid_title

  def deref_main(lexicon, key), do: lexicon.nsid_title <> "." <> :string.titlecase(key)

  def fields(schema) do
    schema.fields
    |> Enum.map(fn field -> "field :#{field.name}, #{field.ecto_type}" end)
    |> Enum.join("\n    ")
  end

  def operations(schema) do
    params = schema.fields
    |> Enum.map(fn %{name: field_name} -> ":#{field_name}" end)

    required = schema.fields
    |> Enum.filter(fn %{required: required} -> required end)
    |> Enum.map(fn %{name: field_name} -> ":#{field_name}" end)

    constraints = schema.fields
    |> Enum.filter(fn %{constraints: constraints} -> map_size(constraints) > 0 end)
    |> Enum.map(fn field -> constraints(field) end)
    |> Enum.reject(&Enum.empty?/1)

    operations =
      if params != [] do
        ["|> cast(params, [#{Enum.join(params, ", ")}])"]
      else
        []
      end

    operations =
      if required != [] do
        ["|> validate_required([#{Enum.join(required, ", ")}])" | operations]
      else
        operations
      end

    operations =
      if constraints != [] do
        Enum.reduce(constraints, operations, fn constraint, acc ->
          ["|> #{constraint}" | acc]
        end)
      else
        operations
      end

    operations
    |> Enum.reverse()
    |> Enum.join("\n    ")
  end

  def constraints(%{name: field, type: type, constraints: constraints}) do
    # eventually will want to also add constraints for e.g. format of strings to match did, cid-link, etc.
    [minmax_constraint(field, type, constraints)]
    |> Enum.reject(&is_nil/1)
  end

  defp minmax_constraint(field, "integer", %{"minimum" => minimum, "maximum" => maximum}), do: "validate_length(:#{field}, min: #{minimum}, max: #{maximum})"
  defp minmax_constraint(field, "integer", %{"minimum" => minimum}), do: "validate_length(:#{field}, min: #{minimum})"
  defp minmax_constraint(field, "integer", %{"maximum" => maximum}), do: "validate_length(:#{field}, max: #{maximum})"
  defp minmax_constraint(field, "list(bytes)", %{"minLength" => minimum, "maxLength" => maximum}), do: "validate_length(:#{field}, min: #{minimum}, max: #{maximum})"
  defp minmax_constraint(field, "list(bytes)", %{"minLength" => minimum}), do: "validate_length(:#{field}, min: #{minimum})"
  defp minmax_constraint(field, "list(bytes)", %{"maxLength" => maximum}), do: "validate_length(:#{field}, max: #{maximum})"
  defp minmax_constraint(field, "string", %{"minLength" => minimum, "maxLength" => maximum}), do: "validate_length(:#{field}, min: #{minimum}, max: #{maximum}, count: :bytes)"
  defp minmax_constraint(field, "string", %{"minLength" => minimum}), do: "validate_length(:#{field}, min: #{minimum}, count: :bytes)"
  defp minmax_constraint(field, "string", %{"maxLength" => maximum}), do: "validate_length(:#{field}, max: #{maximum}, count: :bytes)"
  defp minmax_constraint(field, "string", %{"minGraphemes" => minimum, "maxGraphemes" => maximum}), do: "validate_length(:#{field}, min: #{minimum}, max: #{maximum}, count: :graphemes)"
  defp minmax_constraint(field, "string", %{"minGraphemes" => minimum}), do: "validate_length(:#{field}, min: #{minimum}, count: :graphemes)"
  defp minmax_constraint(field, "string", %{"maxGraphemes" => maximum}), do: "validate_length(:#{field}, max: #{maximum}, count: :graphemes)"
  defp minmax_constraint(field, "list" <> _, %{"minLength" => minimum, "maxLength" => maximum}), do: "validate_length(:#{field}, min: #{minimum}, max: #{maximum})"
  defp minmax_constraint(field, "list" <> _, %{"minLength" => minimum}), do: "validate_length(:#{field}, min: #{minimum})"
  defp minmax_constraint(field, "list" <> _, %{"maxLength" => maximum}), do: "validate_length(:#{field}, max: #{maximum})"
  defp minmax_constraint(_, _, _), do: nil
end

defmodule Lexgen.Types do
  @doc """
  Convert a field definition to an Ecto type.
  """
  @spec to_ecto(map()) :: String.t()
  def to_ecto(%{"type" => "ref", "ref" => _ref}), do: ":map"
  def to_ecto(%{"type" => "union", "refs" => _refs}), do: ":map"
  def to_ecto(%{"type" => "string", "format" => "datetime"}), do: ":utc_datetime"
  def to_ecto(%{"type" => "string"}), do: ":string"
  def to_ecto(%{"type" => "cid-link"}), do: ":string"
  def to_ecto(%{"type" => "null"}), do: ":nil"
  def to_ecto(%{"type" => "integer"}), do: ":integer"
  def to_ecto(%{"type" => "boolean"}), do: ":boolean"
  def to_ecto(%{"type" => "array", "items" => embedded_type}), do: "{:array, #{to_ecto(embedded_type)}}"
  def to_ecto(%{"type" => "bytes"}), do: ":bytes"
  def to_ecto(%{"type" => "blob"}), do: ":map"
  def to_ecto(%{"type" => "unknown"}), do: ":map"

  @doc """
  Convert a field definition to a native Elixir type.
  """
  @spec to_native(String.t(), map()) :: String.t()
  def to_native(nsid, %{"type" => "ref", "ref" => ref}), do: ref_to_type(nsid, ref) <> ".t()"
  def to_native(_nsid, %{"type" => "union", "refs" => _refs}), do: "any"
  def to_native(_nsid, %{"type" => "string", "format" => "datetime"}), do: "DateTime.t()"
  def to_native(_nsid, %{"type" => "string"}), do: "String.t()"
  def to_native(_nsid, %{"type" => "cid-link"}), do: "String.t()"
  def to_native(_nsid, %{"type" => "null"}), do: "nil"
  def to_native(_nsid, %{"type" => "integer"}), do: "integer"
  def to_native(_nsid, %{"type" => "boolean"}), do: "boolean"
  def to_native(nsid, %{"type" => "array", "items" => embedded_type}), do: "list(#{to_native(nsid, embedded_type)})"
  def to_native(_nsid, %{"type" => "bytes"}), do: "list(byte)"
  def to_native(_nsid, %{"type" => "blob"}), do: "map"
  def to_native(nsid, %{"type" => "object", "properties" => props}) do
    list = props
    |> Enum.map(fn {key, value} -> "#{key}: #{to_native(nsid, value)}" end)
    |> Enum.join(", ")
    "%{#{list}}"
  end
  def to_native(_nsid, %{"type" => "object"}), do: "map"
  def to_native(_nsid, %{"type" => "unknown"}), do: "any"

  @doc """
  Convert a `ref` string to a module name.
  """
  @spec ref_to_type(String.t(), String.t()) :: String.t()
  def ref_to_type(nsid, "#" <> id), do: Lexgen.Lexicon.title_nsid(nsid) <> "." <> :string.titlecase(id)

  def ref_to_type(_nsid, ref) do
    # com.atproto.repo.strongRef refers to the "main" type, which is the last segment of the NSID.
    # com.atproto.label.defs#label refers to a non-"main" type, which the bit after the # replaces the last segment of the NSID.
    {nsid, name} = case String.split(ref, "#") do
      [nsid] -> {nsid, "main"}
      [nsid, name] -> {nsid, name}
    end

    Lexgen.Lexicon.title_nsid(nsid) <> "." <> :string.titlecase(name)
  end

  @doc """
  Returns the default value for a given field.

  If the type def already has a `default` key, it is returned as-is. If no explicit default value is provided, the `type` of the field will determine the default value.
  """
  @spec default_value(map()) :: String.t()
  def default_value(%{"type" => "string", "default" => default}), do: "\"#{default}\""
  def default_value(%{"default" => default}), do: default
  def default_value(%{"type" => "integer"}), do: "0"
  def default_value(%{"type" => "boolean"}), do: "false"
  def default_value(%{"type" => "array"}), do: "[]"
  def default_value(_), do: "nil"
end

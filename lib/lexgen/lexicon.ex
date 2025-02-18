defmodule Lexgen.Lexicon do
  @moduledoc """
  Stores information about a Lexicon source JSON file.

  According to the [AT Protocol Lexicon Specification](https://atproto.com/specs/lexicon):

  - A Lexicon is a JSON file.
  - Each Lexicon can have *AT MOST* one primary type.
  - Each `record` and some `object` types require the use of a special `$type` key. This should be the Lexicon's NSID.
  - References to the "main" definition of a Lexicon should *always* exclude the suffix (`#main`). While some scenarios accept using a suffix of `#main`, some scenarios do not, but *all* scenarios accept omitting the suffix for a "main" definition.
  """

  alias Lexgen.Types

  defstruct [
    nsid: nil,
    ns: nil,
    id: nil,
    nsid_title: nil,
    ns_title: nil,
    id_title: nil,
    defs: []
  ]

  @type t :: %__MODULE__{
    nsid: binary(),
    ns: binary(),
    id: binary(),
    nsid_title: binary(),
    ns_title: binary(),
    id_title: binary(),
    defs: [map()]
  }

  @doc """
  Parses a Lexicon JSON string into a Lexicon struct. Also accepts a JSON-decoded map.
  """
  def parse(json) when is_binary(json) do
    json
    |> Jason.decode!()
    |> parse()
  end

  def parse(json) when is_map(json) do
    {ns, id} = split_nsid(json["id"])
    ns_title = ns |> title_nsid()
    id_title = id |> title_nsid()

    %__MODULE__{
      nsid: json["id"],
      ns: ns,
      id: id,
      nsid_title: "#{ns_title}.#{id_title}",
      ns_title: ns_title,
      id_title: id_title,
      defs: json["defs"]
    }
    |> parse_defs()
  end

  @doc """
  Splits an NSID into two components: the "namespace" and the "id".

  For example, `app.bsky.feed.getFeed` would split into `app.bsky.feed` and `getFeed`.
  """
  @spec split_nsid(binary()) :: {binary(), binary()}
  def split_nsid(nsid) do
    segments = nsid |> String.split(".")
    ns_ref = segments |> Enum.drop(-1) |> Enum.join(".")
    id_ref = segments |> List.last()
    {ns_ref, id_ref}
  end

  @doc """
  Converts an NSID into a title-cased string.

  For example, `app.bsky.feed.getFeed` becomes `App.Bsky.Feed.GetFeed`.
  """
  @spec title_nsid(binary()) :: binary()
  def title_nsid(nsid) do
    nsid
    |> String.split(".")
    |> Enum.map(&:string.titlecase/1)
    |> Enum.join(".")
  end

  @doc """
  Parses the `defs` object from a Lexicon JSON file. This assumes that `defs` in the Lexicon struct is an unmodified map from the decoded JSON source.
  """
  def parse_defs(%__MODULE__{defs: defs} = lexicon) do
    parsed_defs = defs
    |> Enum.reduce(%{struct: [], schema: nil, query: nil, procedure: nil}, fn {key, def}, acc ->
      case parse_def(lexicon, key, def) do
        nil -> acc
        parsed_def ->
          case parsed_def.type do
            :struct -> Map.update(acc, :struct, [parsed_def], fn existing -> [parsed_def | existing] end)
            type -> Map.put(acc, type, parsed_def)
          end
      end
    end)

    Map.put(lexicon, :defs, parsed_defs)
  end

  @doc """
  Parses a single definition from a Lexicon JSON file.
  """
  def parse_def(lexicon, key, %{"type" => "object"} = def) do
    %{
      type: :struct,
      key: key,
      fields: build_fields(lexicon, def),
      description: def["description"]
    }
  end

  def parse_def(lexicon, key, %{"type" => "record"} = def) do
    # Right now we only support `integer` and `uuid` primary key types.
    # The TID type is an integer with a kinda-base32 encoded string representation.
    # All records *not* specifying TID currently do not have explicit rules around
    # the key type and therefore we default to `:binary_id`.
    pktype = if def["key"] == "tid", do: ":id", else: ":binary_id"

    %{
      type: :schema,
      key: key,
      pktype: pktype,
      fields: build_fields(lexicon, def["record"]),
      description: def["description"]
    }
  end

  def parse_def(lexicon, key, %{"type" => "query"} = def) do
    %{
      type: :query,
      key: key,
      nsid: lexicon.nsid,
      input: build_fields(lexicon, def["parameters"]),
      output: parse_output(lexicon, def),
      description: def["description"]
    }
  end

  def parse_def(lexicon, key, %{"type" => "procedure"} = def) do
    %{
      type: :procedure,
      key: key,
      nsid: lexicon.nsid,
      input: build_fields(lexicon, def["input"]["schema"]),
      output: parse_output(lexicon, def),
      description: def["description"]
    }
  end

  def parse_def(_lexicon, _key, _def), do: nil

  def parse_output(lexicon, %{"output" => %{"schema" => schema}}) do
    Types.to_native(lexicon.nsid, schema)
  end

  def parse_output(_, _), do: "any"

  defp build_fields(_, nil), do: []

  defp build_fields(lexicon, def) do
    required =
      case def do
        %{"required" => required} -> required
        _ -> []
      end

    Enum.map(def["properties"] || [], fn {field_name, field_def} ->
      %{
        name: field_name,
        type: Types.to_native(lexicon.nsid, field_def),
        ecto_type: Types.to_ecto(field_def),
        required: Enum.member?(required, field_name),
        constraints: build_constraints(field_def),
        default: Types.default_value(field_def)
      }
    end)
  end

  defp build_constraints(%{"type" => type} = field_def) do
    case constraint_keys(type) do
      nil ->
        %{}

      valid_keys ->
        Enum.reduce(valid_keys, %{}, fn key, acc ->
          case Map.get(field_def, key) do
            nil -> acc
            value -> Map.put(acc, key, value)
          end
        end)
    end
  end

  def constraint_keys("boolean"), do: ["default", "const"]
  def constraint_keys("integer"), do: ["minimum", "maximum", "enum", "default", "const"]
  def constraint_keys("string"), do: ["format", "minLength", "maxLength", "minGraphemes", "maxGraphemes", "knownValues", "enum", "default", "const"]
  def constraint_keys("bytes"), do: ["minLength", "maxLength"]
  def constraint_keys("array"), do: ["minLength", "maxLength", "items"]
  def constraint_keys("blob"), do: ["accept", "maxSize"]
  def constraint_keys("union"), do: ["refs", "closed"]
  def constraint_keys(_), do: nil
end

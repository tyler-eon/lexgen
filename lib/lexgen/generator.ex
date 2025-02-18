defmodule Lexgen.Generator do
  alias Lexgen.Lexicon

  @doc """
  Reads all Lexicons in the given path and generates code for them.

  The `input` path argument is given to `Lexgen.Generator.read_lexicons/1`. See that function for more information about the accepted format of the input path.

  If `output` is given, it is assumed to be a path to a directory where all of the generated source files will be written. The directory will be created if it does not exist.
  """
  def generate(input, output \\ nil) do
    input
    |> read_lexicons()
    |> build_code(output)
  end

  @doc """
  Given a path to one or more Lexicon JSON files, reads the files and parses them into a list of Lexicon structs.

  Note: Uses `Path.wildcard/1` to convert `path` to a list of paths.
  """
  def read_lexicons(path) do
    path
    |> Path.wildcard()
    |> Enum.map(&read_lexicon/1)
  end

  @doc """
  Given a path to a Lexicon JSON file, reads the file and parses it into a Lexicon struct.
  """
  def read_lexicon(path) do
    path
    |> File.read!()
    |> Jason.decode!()
    |> Lexicon.parse()
  end

  @doc """
  Given a list of Lexicon structs, generates Elixir source code files to the given `output` directory.
  """
  def build_code([], _output) do
    IO.puts("No lexicons found in input files.")
  end

  def build_code(lexicons, output) do
    File.mkdir_p!(output)

    IO.puts("Generating common atproto modules...")
    Enum.each(["atproto", "tid"], fn common ->
      code = __DIR__
      |> Path.join(["templates/#{common}.eex"])
      |> EEx.eval_file()

      output
      |> Path.join("#{common}.ex")
      |> File.write!(code)
    end)

    IO.puts("Generating #{length(lexicons)} lexicons...")
    lexicons
    |> Enum.each(fn lexicon ->
      write_lexicon(lexicon, output)
    end)
  end

  defp eval_template(template, lexicon, extra_bindings \\ []) when is_list(extra_bindings) do
    __DIR__
    |> Path.join(["templates/#{template}.eex"])
    |> EEx.eval_file([lexicon: lexicon] ++ extra_bindings)
  end

  defp write_lexicon(lexicon, output) do
    path = lexicon.nsid |> String.replace(".", "/")
    dest = Path.join(output, path)
    File.mkdir_p!(dest)

    write_structs(dest, lexicon)
    write_schema(dest, lexicon)
    write_queries(dest, lexicon)
    write_procedures(dest, lexicon)
  end

  defp write_structs(_dest, %{defs: %{struct: []}}), do: :ok

  defp write_structs(dest, lexicon) do
    code = eval_template("structs", lexicon)
    dest
    |> Path.join("structs.ex")
    |> File.write!(code)
  end

  defp write_schema(_dest, %{defs: %{schema: nil}}), do: :ok

  defp write_schema(dest, lexicon) do
    code = eval_template("schema", lexicon)

    dest
    |> Path.join("schema.ex")
    |> File.write!(code)
  end

  defp write_queries(_dest, %{defs: %{query: nil}}), do: :ok

  defp write_queries(dest, lexicon), do: write_xrpc(dest, lexicon, :query)

  defp write_procedures(_dest, %{defs: %{procedure: nil}}), do: :ok

  defp write_procedures(dest, lexicon), do: write_xrpc(dest, lexicon, :procedure)

  defp write_xrpc(dest, lexicon, type) do
    code = eval_template("xrpc", lexicon, type: type)
    dest
    |> Path.join("xrpc.ex")
    |> File.write!(code)
  end
end

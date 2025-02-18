defmodule Mix.Tasks.Lexgen do
  @moduledoc """
  Generates Elixir source code from AT Protocol lexicons. Lexicons are JSON files which define records, objects, queries, and other parts of the AT Protocol data model.

  By default, this will generate files to `./lib/atproto`. The destination folder can be overridden using the `--output` (or `-o`) option.

  Every non-option argument passed in is assumed to be a path to one or more Lexicon files. If specifying more than one Lexicon input, you may either specify each file individually or use glob-style file patterns (e.g. `lexicons/**/*.json`).

  ## Options

  - `-o, --output`: The destination folder for the generated files.
  - `-d, --delete`: Deletes all existing files in the destination folder before generating new files.
  """

  use Mix.Task

  @shortdoc "Generates Elixir source code from AT Protocol lexicons."

  @switches [
    output: :string,
    delete: :boolean
  ]

  @aliases [
    o: :output,
    d: :delete
  ]

  @impl Mix.Task
  def run(args) do
    {options, paths} = OptionParser.parse!(args, switches: @switches, aliases: @aliases)

    output = Keyword.get(options, :output, "lib/atproto")

    if Keyword.get(options, :delete, false) do
      Mix.shell().info("Deleting previous files at #{output}...")
      File.rm_rf!(output)
    end

    Mix.shell().info("Generating source code from lexicons...")
    Enum.each(paths, fn path ->
      Mix.shell().info("-> #{path}")
      Lexgen.Generator.generate(path, output)
    end)

    Mix.shell().info("Done. Generated files can be found in #{output}.")
  end
end

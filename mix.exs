defmodule Lexgen.MixProject do
  use Mix.Project

  def project do
    [
      app: :lexgen,
      version: "1.0.0",
      elixir: "~> 1.18",
      description: "An Elixir source code generator for AT Protocol Lexicons.",
      package: package(),
      deps: deps()
    ]
  end

  def package do
    [
      maintainers: ["Tyler Eon"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/tyler-eon/lexgen"
      }
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end

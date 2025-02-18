# Lexgen

An Elixir source code generator for AT Protocol [Lexicons](https://atproto.com/specs/lexicon).

The AT Protocol defines a "Lexicon" as a JSON file that adheres to a specific schema to define one or more objects, records, queries, procedures, and/or subscriptions. Because this is a highly-structured specification, it is possible to generate Elixir source code from the Lexicons to make it easier to work with the AT Protocol in Elixir.

## Installation

Available as a [Hex package](https://hex.pm/docs/publish), add it to your `mix.exs` file:

```elixir
def deps do
  [
    {:lexgen, "~> 1.0.0", only: [:dev]}
  ]
end
```

Because Lexgen generates Elixir source code but does not provide any in-app functionality on its own, it is recommended to use it as a development-only dependency. This will help keep your production dependencies clean and avoid unnecessary compile-time and runtime overhead.

Lexgen *can* be used directly from Elixir source code, but it is not recommended. You should prefer to use the `lexgen` Mix task instead.

## AT Protocol/Bluesky Lexicons

You can find the "core" set of Lexicons for the AT Protocol and Bluesky in the `lexicons` directory of [Bluesky's atproto project](https://github.com/bluesky-social/atproto). It is recommend to start with a baseline set of generated files using at least the AT Protocol Lexicons (those in `com/atproto/`).

## Usage

Lexgen makes no assumptions about which Lexicons you are using or where you want the output files to be stored under. You simply pass in one or more paths to the JSON files representing your input Lexicons, optionally specify an output directory, and Lexgen will generate the relevant Elixir source code files.

In addition to source code based on Lexicons, Lexgen will also generate "common" modules that are used by the generated source code. These are still *generated files*, meaning they will end up in the same output directory as the generated source code and does not come directly from this package. You are free to modify these files as necessary to fit your needs, but only if you understand what the code is doing and how so that you don't break the functionality of the generated source code.

## Examples

Generate source code to the default output directory (`./lib/atproto`):

```shell
mix lexgen lexicons/**/*.json
```

Generate source code to a custom output directory:

```shell
mix lexgen --output some/other/directory lexicons/**/*.json
```

Generate source code from multiple Lexicon paths:

```shell
mix lexgen lexicons/**/*.json vendor/lexicons/my-custom-lexicon.json vendor/lexicons/more-custom-lexicons/**/*.json
```

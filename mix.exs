defmodule Permit.Ecto.MixProject do
  @moduledoc false
  use Mix.Project

  @version "0.2.4"
  @source_url "https://github.com/curiosum-dev/permit_ecto"

  def project do
    [
      app: :permit_ecto,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Ecto integration for the Permit authorization library.",
      package: package(),
      dialyzer: [plt_add_apps: [:ex_unit]],
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      maintainers: ["Michał Buszkiewicz"],
      files: ["lib", "mix.exs", "README*"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "test/support/", "test/permit/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:permit, "~> 0.3.3"},
      {:ecto, ">= 3.11.2 and < 4.0.0"},
      {:ecto_sql, ">= 3.11.0"},
      {:postgrex, "~> 0.16", only: :test},
      {:jason, "~> 1.3", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:versioce, "~> 2.0.0", only: [:dev, :test], runtime: false},
      {:git_cli, "~> 0.3.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test, runtime: false},
      {:castore, "~> 1.0", only: :test, runtime: false}
    ]
  end

  defp docs do
    [
      main: "Permit.Ecto",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: [
        "Permit.Operators.DynamicQuery"
      ],
      groups_for_modules: [
        Setup: [Permit.Ecto],
        Permissions: [
          Permit.Ecto.Permissions,
          Permit.Ecto.Permissions.Conjunction,
          Permit.Ecto.Permissions.DynamicQueryJoiner,
          Permit.Ecto.Permissions.ParsedCondition
        ],
        Operators: [
          Permit.Operators.DynamicQuery,
          Permit.Operators.Eq.DynamicQuery,
          Permit.Operators.Ge.DynamicQuery,
          Permit.Operators.Gt.DynamicQuery,
          Permit.Operators.Ilike.DynamicQuery,
          Permit.Operators.In.DynamicQuery,
          Permit.Operators.IsNil.DynamicQuery,
          Permit.Operators.Le.DynamicQuery,
          Permit.Operators.Like.DynamicQuery,
          Permit.Operators.Lt.DynamicQuery,
          Permit.Operators.Match.DynamicQuery,
          Permit.Operators.Neq.DynamicQuery
        ],
        Resolution: [
          Permit.Ecto.Resolver
        ],
        Types: [
          Permit.Ecto.Types,
          Permit.Ecto.Types.ConditionTypes
        ],
        Errors: [
          Permit.Ecto.UnconvertibleConditionError,
          Permit.Ecto.UndefinedConditionError
        ]
      ]
    ]
  end
end

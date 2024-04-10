defmodule Permit.Ecto.MixProject do
  @moduledoc false
  use Mix.Project

  @version "0.2.0"
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
      docs: docs()
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      maintainers: ["Michał Buszkiewicz", "Piotr Lisowski"],
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
      {:permit, "~> 0.2"},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, "~> 0.15.13", only: :test},
      {:jason, "~> 1.3", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
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

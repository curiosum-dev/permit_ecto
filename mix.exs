defmodule Permit.Ecto.MixProject do
  use Mix.Project

  def project do
    [
      app: :permit_ecto,
      version: "0.0.3",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Ecto integration for the Permit authorization library.",
      package: package()
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/curiosum-dev/permit_ecto/"},
      maintainers: ["Michał Buszkiewicz", "Piotr Lisowski"],
      files: ["lib", "mix.exs", "README*"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications:
        case Mix.env() do
          :test -> [:logger]
          :dev -> [:logger]
          _ -> [:logger]
        end
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "test/support/", "test/permit/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:permit, path: "../permit"},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, "~> 0.15.13", only: :test},
      {:jason, "~> 1.3", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end

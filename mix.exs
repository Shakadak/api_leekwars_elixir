defmodule ApiLeekwars.MixProject do
  use Mix.Project

  def project do
    [
      app: :api_leekwars,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:castore, "~> 0.1.1"},
      {:mint, "~> 0.2.1"},
      {:poison, "~> 4.0"}
    ]
  end
end

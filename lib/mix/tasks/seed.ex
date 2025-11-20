defmodule Mix.Tasks.TrailChronicle.Seed do
  @moduledoc """
  Seeds the database with sample data.

  ## Examples

      mix trail_chronicle.seed
      mix trail_chronicle.seed --clear
  """
  use Mix.Task

  @shortdoc "Seeds the database with sample trail running data"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    if "--clear" in args do
      Mix.shell().info("Clearing database first...")
      Code.eval_file("priv/repo/seeds.exs")
    else
      Code.eval_file("priv/repo/seeds.exs")
    end
  end
end

defmodule TrailChronicle.Repo do
  use Ecto.Repo,
    otp_app: :trail_chronicle,
    adapter: Ecto.Adapters.Postgres
end

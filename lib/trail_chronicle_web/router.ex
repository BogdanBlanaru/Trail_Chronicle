defmodule TrailChronicleWeb.Router do
  use TrailChronicleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TrailChronicleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug TrailChronicleWeb.Plugs.Locale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TrailChronicleWeb do
    pipe_through :browser

    live_session :default, on_mount: [TrailChronicleWeb.RestoreLocale] do
      live "/", DashboardLive
      live "/races", RaceLive.Index
      live "/races/new", RaceLive.Form, :new
      live "/races/:id", RaceLive.Show
      live "/races/:id/edit", RaceLive.Form, :edit

      live "/calendar", PlaceholderLive, :calendar
      live "/stats", PlaceholderLive, :stats
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:trail_chronicle, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TrailChronicleWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

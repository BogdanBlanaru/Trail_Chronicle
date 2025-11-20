defmodule TrailChronicleWeb.Router do
  use TrailChronicleWeb, :router

  import TrailChronicleWeb.AthleteAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TrailChronicleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_athlete
    plug TrailChronicleWeb.Plugs.Locale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes (no authentication required)
  scope "/", TrailChronicleWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Auth routes - Only accessible when NOT logged in
  scope "/", TrailChronicleWeb do
    pipe_through [:browser, :redirect_if_athlete_is_authenticated]

    live_session :redirect_if_athlete_is_authenticated,
      on_mount: [{TrailChronicleWeb.AthleteAuth, :redirect_if_athlete_is_authenticated}] do
      live "/athletes/register", AthleteRegistrationLive, :new
      live "/athletes/log_in", AthleteLoginLive, :new
      live "/athletes/reset_password", AthleteForgotPasswordLive, :new
      live "/athletes/reset_password/:token", AthleteResetPasswordLive, :edit
    end

    post "/athletes/log_in", AthleteSessionController, :create
  end

  # Protected routes - Requires authentication
  scope "/", TrailChronicleWeb do
    pipe_through [:browser, :require_authenticated_athlete]

    live_session :require_authenticated_athlete,
      on_mount: [{TrailChronicleWeb.AthleteAuth, :ensure_authenticated}] do
      live "/dashboard", DashboardLive, :index

      # Races
      live "/races", RaceLive.Index, :index
      live "/races/new", RaceLive.Form, :new
      live "/races/:id", RaceLive.Show, :show
      live "/races/:id/edit", RaceLive.Form, :edit

      # New Pages
      live "/calendar", CalendarLive, :index
      live "/stats", StatsLive, :index

      # Settings
      live "/athletes/settings", AthleteSettingsLive, :edit
      live "/athletes/settings/confirm_email/:token", AthleteSettingsLive, :confirm_email
    end
  end

  # Auth routes accessible when logged in
  scope "/", TrailChronicleWeb do
    pipe_through [:browser]

    delete "/athletes/log_out", AthleteSessionController, :delete

    live_session :current_athlete,
      on_mount: [{TrailChronicleWeb.AthleteAuth, :mount_current_athlete}] do
      live "/athletes/confirm/:token", AthleteConfirmationLive, :edit
      live "/athletes/confirm", AthleteConfirmationInstructionsLive, :new
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

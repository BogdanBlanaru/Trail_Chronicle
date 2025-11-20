defmodule TrailChronicleWeb.AthleteAuth do
  use TrailChronicleWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias TrailChronicle.Accounts

  # Make the remember me cookie valid for 60 days.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_trail_chronicle_web_athlete_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the athlete in.
  """
  def log_in_athlete(conn, athlete, params \\ %{}) do
    token = Accounts.generate_athlete_session_token(athlete)
    athlete_return_to = get_session(conn, :athlete_return_to)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> put_session(:locale, athlete.preferred_language || "en")
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: athlete_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole session
  # to avoid fixation attacks. If there is any data in the session
  # you may want to preserve after log in/log out, you must explicitly
  # fetch the session data before clearing and then immediately set it
  # after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the athlete out.
  """
  def log_out_athlete(conn) do
    athlete_token = get_session(conn, :athlete_token)
    athlete_token && Accounts.delete_athlete_session_token(athlete_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      TrailChronicleWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    locale = get_session(conn, :locale) || "en"

    conn
    |> renew_session()
    |> put_session(:locale, locale)
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the athlete by looking into the session and remember me token.
  """
  def fetch_current_athlete(conn, _opts) do
    {athlete_token, conn} = ensure_athlete_token(conn)
    athlete = athlete_token && Accounts.get_athlete_by_session_token(athlete_token)
    assign(conn, :current_athlete, athlete)
  end

  defp ensure_athlete_token(conn) do
    if token = get_session(conn, :athlete_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Handles mounting and authenticating the current_athlete in LiveViews.
  """
  def on_mount(:mount_current_athlete, _params, session, socket) do
    {:cont, mount_current_athlete(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_athlete(socket, session)

    if socket.assigns.current_athlete do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/athletes/log_in")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_athlete_is_authenticated, _params, session, socket) do
    socket = mount_current_athlete(socket, session)

    if socket.assigns.current_athlete do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_athlete(socket, session) do
    socket =
      Phoenix.Component.assign_new(socket, :current_athlete, fn ->
        if athlete_token = session["athlete_token"] do
          Accounts.get_athlete_by_session_token(athlete_token)
        end
      end)

    # Read locale from athlete's preferred language or default to "en"
    locale =
      if socket.assigns.current_athlete do
        socket.assigns.current_athlete.preferred_language || "en"
      else
        session["locale"] || "en"
      end

    # Set the locale for Gettext
    Gettext.put_locale(TrailChronicleWeb.Gettext, locale)

    socket = Phoenix.Component.assign_new(socket, :locale, fn -> locale end)

    # Set current_path for navigation highlighting
    socket =
      Phoenix.Component.assign_new(socket, :current_path, fn ->
        # Default path, will be overridden by LiveView
        "/"
      end)

    socket
  end

  @doc """
  Used for routes that require the athlete to not be authenticated.
  """
  def redirect_if_athlete_is_authenticated(conn, _opts) do
    if conn.assigns[:current_athlete] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the athlete to be authenticated.
  """
  def require_authenticated_athlete(conn, _opts) do
    if conn.assigns[:current_athlete] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/athletes/log_in")
      |> halt()
    end
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:athlete_token, token)
    |> put_session(:live_socket_id, "athletes_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :athlete_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/"
end

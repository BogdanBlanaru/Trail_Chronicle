defmodule TrailChronicleWeb.Plugs.Locale do
  @moduledoc """
  Plug that sets the locale. It retrieves it in order from:
  1. The current athlete's preferences (if authenticated)
  2. URL query parameters (e.g., `?locale=ro`)
  3. Session
  4. Cookies
  5. Default config
  """
  import Plug.Conn
  use Gettext, backend: TrailChronicleWeb.Gettext
  alias TrailChronicle.Accounts.Athlete

  @locales Gettext.known_locales(TrailChronicleWeb.Gettext)

  def init(_opts), do: nil

  def call(conn, _opts) do
    locale =
      from_current_athlete(conn) ||
        from_params(conn) ||
        from_session(conn) ||
        from_cookies(conn) ||
        from_platform_settings()

    Gettext.put_locale(TrailChronicleWeb.Gettext, locale)

    conn
    |> assign(:locale, locale)
    |> persist_locale_in_session(locale)
    |> persist_locale_in_cookies(locale)
  end

  defp from_current_athlete(%Plug.Conn{
         assigns: %{current_athlete: %Athlete{preferred_language: locale}}
       }) do
    validate_locale(locale)
  end

  defp from_current_athlete(_conn), do: nil

  defp from_params(conn) do
    conn.params["locale"] |> validate_locale()
  end

  defp from_session(conn) do
    conn |> get_session(:locale) |> validate_locale()
  end

  defp from_cookies(conn) do
    conn.cookies["locale"] |> validate_locale()
  end

  defp from_platform_settings, do: "en"

  defp validate_locale(locale) when locale in @locales, do: locale
  defp validate_locale(_locale), do: nil

  defp persist_locale_in_session(conn, locale) do
    existing_locale = get_session(conn, :locale)

    if !existing_locale || existing_locale != locale do
      put_session(conn, :locale, locale)
    else
      conn
    end
  end

  defp persist_locale_in_cookies(%Plug.Conn{cookies: %{"locale" => locale}} = conn, locale),
    do: conn

  defp persist_locale_in_cookies(conn, locale) do
    put_resp_cookie(conn, "locale", locale, max_age: 30 * 24 * 60 * 60)
  end
end

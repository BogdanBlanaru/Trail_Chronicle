defmodule TrailChronicleWeb.Plugs.SetLocale do
  @moduledoc """
  Plug to set the locale from session or default to English.
  """
  import Plug.Conn
  alias TrailChronicleWeb.Locale

  def init(default), do: default

  def call(conn, _default) do
    locale = Locale.get_locale_from_session(conn)
    Gettext.put_locale(TrailChronicleWeb.Gettext, locale)

    conn
    |> assign(:locale, locale)
    |> put_session(:locale, locale)
  end
end

defmodule TrailChronicleWeb.RestoreLocale do
  @moduledoc """
  Finds the athlete's locale and sets it in the socket assigns.
  """
  use Phoenix.LiveView
  use Gettext, backend: TrailChronicleWeb.Gettext
  alias TrailChronicle.Accounts.Athlete
  alias Phoenix.LiveView.Socket

  @locales Gettext.known_locales(TrailChronicleWeb.Gettext)

  def on_mount(:default, params, session, socket) do
    locale =
      from_current_athlete(socket) ||
        from_params(params) ||
        from_session(session) ||
        from_cookies(socket) ||
        from_platform_settings()

    Gettext.put_locale(TrailChronicleWeb.Gettext, locale)
    {:cont, assign(socket, :locale, locale)}
  end

  defp from_current_athlete(%Socket{
         assigns: %{current_athlete: %Athlete{preferred_language: locale}}
       }) do
    validate_locale(locale)
  end

  defp from_current_athlete(_socket), do: nil

  defp from_params(%{"locale" => locale}), do: validate_locale(locale)
  defp from_params(_params), do: nil

  defp from_session(%{"locale" => locale}), do: validate_locale(locale)
  defp from_session(_session), do: nil

  defp from_cookies(%Socket{private: %{connect_info: %{cookies: %{"locale" => locale}}}}),
    do: validate_locale(locale)

  defp from_cookies(_socket), do: nil

  defp from_platform_settings, do: "en"

  defp validate_locale(locale) when locale in @locales, do: locale
  defp validate_locale(_locale), do: nil
end

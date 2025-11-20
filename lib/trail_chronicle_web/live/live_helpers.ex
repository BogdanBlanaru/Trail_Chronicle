defmodule TrailChronicleWeb.LiveHelpers do
  @moduledoc """
  Shared helpers for LiveViews
  """
  import Phoenix.Component
  import Phoenix.LiveView

  alias TrailChronicle.Accounts

  def handle_locale_switch(socket, locale) when locale in ["en", "ro", "fr"] do
    # Get current athlete
    athlete = socket.assigns.current_athlete

    # Update athlete's preferred language in database
    case Accounts.update_athlete_locale(athlete, locale) do
      {:ok, _athlete} ->
        # Set locale for current process
        Gettext.put_locale(TrailChronicleWeb.Gettext, locale)

        # Redirect to same page to force full re-render with new locale
        socket
        |> assign(:locale, locale)
        |> redirect(to: socket.assigns[:current_path] || "/")

      {:error, _} ->
        socket
    end
  end

  def handle_locale_switch(socket, _locale), do: socket
end

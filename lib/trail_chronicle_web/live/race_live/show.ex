defmodule TrailChronicleWeb.RaceLive.Show do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.Racing

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    athlete = socket.assigns.current_athlete

    if athlete do
      try do
        race = Racing.get_race_with_athlete!(id)

        if race.athlete_id == athlete.id do
          {:ok,
           socket
           |> assign(:race, race)
           |> assign(:pace, calculate_pace(race.distance_km, race.finish_time_seconds))
           |> assign(:current_path, "/races/#{id}")
           |> assign(:page_title, race.name)}
        else
          {:ok,
           socket
           |> put_flash(:error, gettext("You do not have permission to view this race."))
           |> redirect(to: ~p"/races")}
        end
      rescue
        Ecto.NoResultsError ->
          {:ok,
           socket
           |> put_flash(:error, gettext("Race not found."))
           |> redirect(to: ~p"/races")}
      end
    else
      {:ok, redirect(socket, to: ~p"/athletes/log_in")}
    end
  end

  # ... rest of the file remains the same ...
  @impl true
  def handle_event("delete", _params, socket) do
    case Racing.delete_race(socket.assigns.race) do
      {:ok, _race} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Race deleted successfully."))
         |> redirect(to: ~p"/races")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to delete race."))}
    end
  end

  @impl true
  def handle_event("switch-locale", %{"locale" => locale}, socket) do
    {:noreply, TrailChronicleWeb.LiveHelpers.handle_locale_switch(socket, locale)}
  end

  defp format_time(nil), do: "—"

  defp format_time(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    secs = rem(seconds, 60)
    "#{pad(hours)}:#{pad(minutes)}:#{pad(secs)}"
  end

  defp pad(num), do: String.pad_leading(to_string(num), 2, "0")

  defp calculate_pace(distance_km, time_seconds)
       when is_struct(distance_km, Decimal) and is_integer(time_seconds) do
    dist_float = Decimal.to_float(distance_km)

    if dist_float > 0 and time_seconds > 0 do
      pace_seconds = time_seconds / dist_float
      minutes = div(trunc(pace_seconds), 60)
      seconds = rem(trunc(pace_seconds), 60)
      "#{minutes}:#{pad(seconds)}"
    else
      nil
    end
  end

  defp calculate_pace(_, _), do: nil
end

defmodule TrailChronicleWeb.RaceLive.Show do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.{Accounts, Racing}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    athlete = Accounts.get_athlete_by_email("bogdan@example.com")

    if athlete do
      race = Racing.get_race_with_athlete!(id)

      # Check if this race belongs to the current athlete
      if race.athlete_id == athlete.id do
        {:ok,
         socket
         |> assign(:athlete, athlete)
         |> assign(:race, race)
         |> assign(:current_path, "/races/#{id}")
         |> assign(:page_title, race.name)}
      else
        {:ok,
         socket
         |> put_flash(:error, "Race not found")
         |> redirect(to: ~p"/races")}
      end
    else
      {:ok, redirect(socket, to: ~p"/")}
    end
  end

  @impl true
  def handle_event("delete", _params, socket) do
    case Racing.delete_race(socket.assigns.race) do
      {:ok, _race} ->
        {:noreply,
         socket
         |> put_flash(:info, "Race deleted successfully")
         |> redirect(to: ~p"/races")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete race")}
    end
  end

  # Helper functions
  defp format_time(nil), do: "N/A"

  defp format_time(seconds) when is_integer(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    secs = rem(seconds, 60)

    "#{pad(hours)}:#{pad(minutes)}:#{pad(secs)}"
  end

  defp pad(num), do: String.pad_leading(to_string(num), 2, "0")

  defp calculate_pace(distance_km, time_seconds)
       when is_number(distance_km) and is_integer(time_seconds) do
    if Decimal.compare(distance_km, 0) == :gt and time_seconds > 0 do
      distance_float = Decimal.to_float(distance_km)
      pace_seconds = time_seconds / distance_float
      minutes = div(trunc(pace_seconds), 60)
      seconds = rem(trunc(pace_seconds), 60)
      "#{minutes}:#{pad(seconds)} min/km"
    else
      "N/A"
    end
  end

  defp calculate_pace(_distance_km, _time_seconds), do: "N/A"

  defp status_badge_class("completed"), do: "bg-green-100 text-green-800"
  defp status_badge_class("upcoming"), do: "bg-yellow-100 text-yellow-800"
  defp status_badge_class("cancelled"), do: "bg-red-100 text-red-800"
  defp status_badge_class("dns"), do: "bg-gray-100 text-gray-800"
  defp status_badge_class("dnf"), do: "bg-orange-100 text-orange-800"
  defp status_badge_class(_), do: "bg-gray-100 text-gray-800"

  defp status_text("completed"), do: "✓ Completed"
  defp status_text("upcoming"), do: "📅 Upcoming"
  defp status_text("cancelled"), do: "❌ Cancelled"
  defp status_text("dns"), do: "DNS (Did Not Start)"
  defp status_text("dnf"), do: "DNF (Did Not Finish)"
  defp status_text(status), do: status

  defp terrain_difficulty_stars(nil), do: []

  defp terrain_difficulty_stars(difficulty) when difficulty in 1..5 do
    for _ <- 1..difficulty, do: "⭐"
  end

  defp terrain_difficulty_stars(_), do: []
end

defmodule TrailChronicleWeb.RaceLive.Index do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.{Accounts, Racing}

  @impl true
  def mount(_params, _session, socket) do
    athlete = Accounts.get_athlete_by_email("bogdan@example.com")

    if athlete do
      races = Racing.list_races(athlete)

      {:ok,
       socket
       |> assign(:athlete, athlete)
       |> assign(:races, races)
       |> assign(:filter, "all")
       |> assign(:current_path, "/races")
       |> assign(:page_title, "All Races")}
    else
      {:ok, redirect(socket, to: ~p"/")}
    end
  end

  @impl true
  def handle_event("filter", %{"filter" => filter}, socket) do
    races =
      case filter do
        "completed" -> Racing.list_completed_races(socket.assigns.athlete)
        "upcoming" -> Racing.list_upcoming_races(socket.assigns.athlete)
        _ -> Racing.list_races(socket.assigns.athlete)
      end

    {:noreply,
     socket
     |> assign(:races, races)
     |> assign(:filter, filter)}
  end

  defp format_time(nil), do: "N/A"

  defp format_time(seconds) when is_integer(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    secs = rem(seconds, 60)

    "#{pad(hours)}:#{pad(minutes)}:#{pad(secs)}"
  end

  defp pad(num), do: String.pad_leading(to_string(num), 2, "0")
end

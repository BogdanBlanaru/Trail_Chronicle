defmodule TrailChronicleWeb.RaceLive.Index do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.Racing

  @impl true
  def mount(_params, _session, socket) do
    athlete = socket.assigns.current_athlete
    races = Racing.list_races(athlete)

    socket =
      socket
      |> assign(:athlete, athlete)
      |> assign(:raw_races, races)
      |> assign(:filter, "all")
      |> assign(:search_query, "")
      |> assign(:sort_by, "date_desc")
      |> assign(:current_path, "/races")
      |> assign(:page_title, gettext("My Races"))
      |> assign_filtered_races()

    {:ok, socket}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter}, socket) do
    athlete = socket.assigns.athlete

    new_raw_races =
      case filter do
        "completed" -> Racing.list_completed_races(athlete)
        "upcoming" -> Racing.list_upcoming_races(athlete)
        _ -> Racing.list_races(athlete)
      end

    {:noreply,
     socket
     |> assign(:filter, filter)
     |> assign(:raw_races, new_raw_races)
     |> assign_filtered_races()}
  end

  # Handle Search - Robust pattern matching for different event payloads
  @impl true
  def handle_event("search", params, socket) do
    # Extract query from "value" (keyup) or "query" (change) or nested "value"
    query = Map.get(params, "value") || Map.get(params, "query") || ""

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign_filtered_races()}
  end

  # Handle Sort
  @impl true
  def handle_event("sort", %{"sort_by" => sort_by}, socket) do
    {:noreply,
     socket
     |> assign(:sort_by, sort_by)
     |> assign_filtered_races()}
  end

  @impl true
  def handle_event("switch-locale", %{"locale" => locale}, socket) do
    {:noreply, TrailChronicleWeb.LiveHelpers.handle_locale_switch(socket, locale)}
  end

  # --- Pipeline ---

  defp assign_filtered_races(socket) do
    filtered =
      socket.assigns.raw_races
      |> filter_by_text(socket.assigns.search_query)
      |> sort_races(socket.assigns.sort_by)

    assign(socket, :filtered_races, filtered)
  end

  defp filter_by_text(races, ""), do: races
  defp filter_by_text(races, nil), do: races

  defp filter_by_text(races, query) do
    query = String.downcase(query)

    Enum.filter(races, fn race ->
      name = String.downcase(race.name || "")
      city = String.downcase(race.city || "")
      country = String.downcase(race.country || "")

      String.contains?(name, query) or String.contains?(city, query) or
        String.contains?(country, query)
    end)
  end

  # --- Sorting Logic ---

  # Date Sorting
  defp sort_races(races, "date_desc"), do: Enum.sort_by(races, & &1.race_date, {:desc, Date})
  defp sort_races(races, "date_asc"), do: Enum.sort_by(races, & &1.race_date, {:asc, Date})

  # Distance Sorting (Explicit Decimal Comparison)
  defp sort_races(races, "distance_desc") do
    Enum.sort(races, fn a, b ->
      val_a = a.distance_km || Decimal.new(0)
      val_b = b.distance_km || Decimal.new(0)
      # Descending
      Decimal.compare(val_a, val_b) != :lt
    end)
  end

  defp sort_races(races, "distance_asc") do
    Enum.sort(races, fn a, b ->
      val_a = a.distance_km || Decimal.new(0)
      val_b = b.distance_km || Decimal.new(0)
      # Ascending
      Decimal.compare(val_a, val_b) == :lt
    end)
  end

  # Name Sorting
  defp sort_races(races, "name_asc") do
    Enum.sort_by(races, &String.downcase(&1.name || ""))
  end

  # Fallback
  defp sort_races(races, _), do: races

  # --- Helpers ---
  defp format_time(nil), do: "—"

  defp format_time(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    secs = rem(seconds, 60)
    "#{pad(hours)}:#{pad(minutes)}:#{pad(secs)}"
  end

  defp pad(num), do: String.pad_leading(to_string(num), 2, "0")
end

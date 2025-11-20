defmodule TrailChronicleWeb.StatsLive do
  use TrailChronicleWeb, :live_view
  alias TrailChronicle.Racing

  def mount(_params, _session, socket) do
    athlete = socket.assigns.current_athlete

    if athlete do
      available_years = Racing.list_race_years(athlete)
      current_year = Date.utc_today().year
      # Default to current year if valid, otherwise newest available
      selected_year =
        if current_year in available_years,
          do: current_year,
          else: List.first(available_years) || current_year

      {ytd, chart_data, type_dist, heatmap_data} = fetch_year_data(athlete, selected_year)
      pbs = Racing.get_personal_bests(athlete)

      {:ok,
       socket
       |> assign(:current_path, "/stats")
       |> assign(:selected_year, selected_year)
       |> assign(:available_years, available_years)
       |> assign(:ytd, ytd)
       |> assign(:chart_data, chart_data)
       # For Donut Chart
       |> assign(:type_dist, type_dist)
       # For Calendar Heatmap
       |> assign(:heatmap_data, heatmap_data)
       |> assign(:pbs, pbs)
       |> assign(:page_title, gettext("Statistics"))}
    else
      {:ok, redirect(socket, to: ~p"/athletes/log_in")}
    end
  end

  def handle_event("select-year", %{"year" => year_str}, socket) do
    year = String.to_integer(year_str)

    {ytd, chart_data, type_dist, heatmap_data} =
      fetch_year_data(socket.assigns.current_athlete, year)

    {:noreply,
     socket
     |> assign(:selected_year, year)
     |> assign(:ytd, ytd)
     |> assign(:chart_data, chart_data)
     |> assign(:type_dist, type_dist)
     |> assign(:heatmap_data, heatmap_data)}
  end

  def handle_event("switch-locale", %{"locale" => locale}, socket) do
    {:noreply, TrailChronicleWeb.LiveHelpers.handle_locale_switch(socket, locale)}
  end

  defp fetch_year_data(athlete, year) do
    ytd = Racing.get_yearly_stats(athlete, year)
    monthly_raw = Racing.get_monthly_distance_stats(athlete, year)
    type_dist = Racing.get_races_by_type(athlete, year)
    heatmap_data = Racing.get_activity_dates(athlete, year)

    chart_data =
      1..12
      |> Enum.map(fn m ->
        found = Enum.find(monthly_raw, &(&1.month == m))
        %{month: m, total_km: found[:total_km] || Decimal.new(0)}
      end)

    {ytd, chart_data, type_dist, heatmap_data}
  end

  # --- SVG Helpers ---

  defp max_chart_value(data) do
    Enum.map(data, & &1.total_km)
    |> Enum.max_by(&Decimal.to_float/1, fn -> Decimal.new(10) end)
    |> Decimal.to_float()
    |> max(10.0)
  end

  defp bar_height(val, max_val) do
    v = Decimal.to_float(val)
    v / max_val * 100
  end

  # Calculates pie chart segments
  defp calculate_pie_segments(type_dist) do
    total = Enum.sum(Map.values(type_dist))

    if total == 0 do
      []
    else
      # Sort for consistent colors
      sorted = Enum.sort(type_dist)

      {segments, _} =
        Enum.map_reduce(sorted, 0, fn {type, count}, acc_percent ->
          percent = count / total * 100
          # Simple dasharray calculation for SVG circle: stroke-dasharray="value 100"
          # We offset it by the previous accumulated percentage
          {%{type: type, percent: percent, offset: 100 - acc_percent}, acc_percent + percent}
        end)

      segments
    end
  end

  defp format_time(nil), do: "-"

  defp format_time(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    "#{hours}h #{minutes}m"
  end

  defp month_short(m), do: Enum.at(~w(J F M A M J J A S O N D), m - 1)

  # Heatmap Helpers
  defp get_heatmap_color(date, heatmap_data) do
    case Map.get(heatmap_data, date) do
      "completed" -> "bg-emerald-500"
      "upcoming" -> "bg-amber-400"
      "dnf" -> "bg-rose-400"
      "dns" -> "bg-slate-400"
      _ -> "bg-slate-100"
    end
  end

  defp weeks_in_year(year) do
    start_date = Date.new!(year, 1, 1)
    # 53 columns covers a full year
    0..52
    |> Enum.map(fn w ->
      # Get date for start of that week
      Date.add(start_date, w * 7)
    end)
  end
end

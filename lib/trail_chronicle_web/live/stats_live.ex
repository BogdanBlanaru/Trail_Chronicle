defmodule TrailChronicleWeb.StatsLive do
  use TrailChronicleWeb, :live_view
  alias TrailChronicle.Racing

  def mount(_params, _session, socket) do
    athlete = socket.assigns.current_athlete

    if athlete do
      # Determine available years, default to current year if no data
      available_years = Racing.list_race_years(athlete)
      current_year = Date.utc_today().year

      selected_year =
        if current_year in available_years,
          do: current_year,
          else: List.first(available_years) || current_year

      # Fetch initial data
      {ytd, chart_data} = fetch_year_data(athlete, selected_year)
      pbs = Racing.get_personal_bests(athlete)

      {:ok,
       socket
       |> assign(:current_path, "/stats")
       |> assign(:selected_year, selected_year)
       |> assign(:available_years, available_years)
       |> assign(:ytd, ytd)
       |> assign(:chart_data, chart_data)
       |> assign(:pbs, pbs)
       |> assign(:page_title, gettext("Statistics"))}
    else
      {:ok, redirect(socket, to: ~p"/athletes/log_in")}
    end
  end

  def handle_event("select-year", %{"year" => year_str}, socket) do
    year = String.to_integer(year_str)
    {ytd, chart_data} = fetch_year_data(socket.assigns.current_athlete, year)

    {:noreply,
     socket
     |> assign(:selected_year, year)
     |> assign(:ytd, ytd)
     |> assign(:chart_data, chart_data)}
  end

  def handle_event("switch-locale", %{"locale" => locale}, socket) do
    {:noreply, TrailChronicleWeb.LiveHelpers.handle_locale_switch(socket, locale)}
  end

  defp fetch_year_data(athlete, year) do
    ytd = Racing.get_yearly_stats(athlete, year)
    monthly_raw = Racing.get_monthly_distance_stats(athlete, year)

    # Fill gaps for months with 0 activity
    chart_data =
      1..12
      |> Enum.map(fn m ->
        found = Enum.find(monthly_raw, &(&1.month == m))
        %{month: m, total_km: found[:total_km] || Decimal.new(0)}
      end)

    {ytd, chart_data}
  end

  # --- View Helpers ---

  defp format_time(nil), do: "-"

  defp format_time(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    "#{hours}h #{minutes}m"
  end

  defp month_short(m), do: Enum.at(~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec), m - 1)

  # SVG Calculation helpers
  defp max_chart_value(data) do
    Enum.map(data, & &1.total_km)
    |> Enum.max_by(&Decimal.to_float/1, fn -> Decimal.new(10) end)
    |> Decimal.to_float()
    # Minimum scale
    |> max(10.0)
  end

  defp bar_height(val, max_val) do
    v = Decimal.to_float(val)
    v / max_val * 100
  end
end

defmodule TrailChronicleWeb.CalendarLive do
  use TrailChronicleWeb, :live_view
  alias TrailChronicle.Racing

  def mount(_params, _session, socket) do
    athlete = socket.assigns.current_athlete

    today = Date.utc_today()
    # Start with current month view
    current_view_date = Date.beginning_of_month(today)

    if athlete do
      {:ok,
       socket
       |> assign(:current_path, "/calendar")
       |> assign(:current_view_date, current_view_date)
       |> assign(:today, today)
       |> assign(:page_title, gettext("Calendar"))
       |> fetch_month_data()}
    else
      {:ok, redirect(socket, to: ~p"/athletes/log_in")}
    end
  end

  def handle_event("prev-month", _, socket) do
    new_date = Date.add(socket.assigns.current_view_date, -1) |> Date.beginning_of_month()
    {:noreply, socket |> assign(:current_view_date, new_date) |> fetch_month_data()}
  end

  def handle_event("next-month", _, socket) do
    new_date = Date.add(socket.assigns.current_view_date, 32) |> Date.beginning_of_month()
    {:noreply, socket |> assign(:current_view_date, new_date) |> fetch_month_data()}
  end

  def handle_event("today", _, socket) do
    today = Date.utc_today() |> Date.beginning_of_month()
    {:noreply, socket |> assign(:current_view_date, today) |> fetch_month_data()}
  end

  def handle_event("switch-locale", %{"locale" => locale}, socket) do
    {:noreply, TrailChronicleWeb.LiveHelpers.handle_locale_switch(socket, locale)}
  end

  defp fetch_month_data(socket) do
    athlete = socket.assigns.current_athlete
    date = socket.assigns.current_view_date

    start_of_month = Date.beginning_of_month(date)

    # Calendar math: Find the Monday before the 1st of the month
    dow = Date.day_of_week(start_of_month, :monday)
    calendar_start = Date.add(start_of_month, -(dow - 1))

    # Fetch races for a 6-week window to be safe
    calendar_end = Date.add(calendar_start, 41)

    races = Racing.list_races_between(athlete, calendar_start, calendar_end)
    races_map = Enum.group_by(races, & &1.race_date)

    socket
    |> assign(:calendar_start, calendar_start)
    |> assign(:races_map, races_map)
  end

  defp calendar_days(start_date) do
    0..41 |> Enum.map(fn i -> Date.add(start_date, i) end)
  end
end

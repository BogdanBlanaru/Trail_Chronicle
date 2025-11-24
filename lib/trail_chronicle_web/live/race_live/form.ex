defmodule TrailChronicleWeb.RaceLive.Form do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.{Racing}
  alias TrailChronicle.Racing.Race

  @impl true
  def mount(params, _session, socket) do
    athlete = socket.assigns.current_athlete

    if athlete do
      shoes = Racing.list_active_shoes(athlete)

      shoe_options =
        Enum.map(shoes, fn s ->
          {"#{s.brand} #{s.model} (#{Decimal.round(s.current_distance_km, 0)}km)", s.id}
        end)

      {:ok,
       socket
       |> assign(:athlete, athlete)
       # Add to assigns
       |> assign(:shoe_options, shoe_options)
       |> apply_action(socket.assigns.live_action, params)}
    else
      {:ok, redirect(socket, to: ~p"/athletes/log_in")}
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("Log New Race"))
    # FIX: Set as String
    |> assign(:current_path, "/races/new")
    |> assign(:race, %Race{})
    |> assign(:changeset, Racing.change_race(%Race{}))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    race = Racing.get_race!(id)

    if race.athlete_id == socket.assigns.athlete.id do
      socket
      |> assign(:page_title, gettext("Edit Race"))
      # FIX: Set as String
      |> assign(:current_path, "/races/#{id}/edit")
      |> assign(:race, race)
      |> assign(:changeset, Racing.change_race(race))
    else
      socket
      |> put_flash(:error, gettext("Unauthorized access."))
      |> redirect(to: ~p"/races")
    end
  end

  # ... (Rest of handle_events remain the same) ...

  @impl true
  def handle_event("validate", %{"race" => race_params}, socket) do
    changeset =
      socket.assigns.race
      |> Racing.change_race(race_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"race" => race_params}, socket) do
    save_race(socket, socket.assigns.live_action, race_params)
  end

  @impl true
  def handle_event("switch-locale", %{"locale" => locale}, socket) do
    {:noreply, TrailChronicleWeb.LiveHelpers.handle_locale_switch(socket, locale)}
  end

  defp save_race(socket, :new, race_params) do
    case Racing.create_race_with_shoe(socket.assigns.athlete, race_params) do
      {:ok, race} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Race created successfully!"))
         |> redirect(to: ~p"/races/#{race.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp save_race(socket, :edit, race_params) do
    case Racing.update_race_with_shoe(socket.assigns.race, race_params) do
      {:ok, race} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Race updated successfully!"))
         |> redirect(to: ~p"/races/#{race.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end

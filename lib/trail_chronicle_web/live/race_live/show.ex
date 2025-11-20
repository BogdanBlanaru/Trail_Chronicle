defmodule TrailChronicleWeb.RaceLive.Show do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.{Accounts, Racing}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    athlete = socket.assigns.current_athlete

    if athlete do
      try do
        race = Racing.get_race_with_athlete!(id)

        if race.athlete_id == athlete.id do
          photos = Racing.list_race_photos(race.id)

          {:ok,
           socket
           |> assign(:race, race)
           |> assign(:photos, photos)
           |> assign(:pace, calculate_pace(race.distance_km, race.finish_time_seconds))
           |> assign(:current_path, "/races/#{id}")
           |> assign(:page_title, race.name)
           # Allow uploads
           |> allow_upload(:gpx, accept: ~w(.gpx), max_entries: 1)
           |> allow_upload(:photos, accept: ~w(.jpg .jpeg .png), max_entries: 10)}
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

  # --- UPLOAD HANDLERS ---

  # FIX 1: Required to prevent FunctionClauseError during file selection
  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save_gpx", _params, socket) do
    race = socket.assigns.race

    consume_uploaded_entries(socket, :gpx, fn %{path: path}, _entry ->
      case Racing.update_race_gpx(race, path) do
        {:ok, updated_race} -> {:ok, updated_race}
        _ -> {:error, "Failed to parse"}
      end
    end)
    |> case do
      [updated_race] ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Route added successfully!"))
         |> assign(:race, updated_race)}

      _ ->
        {:noreply, socket |> put_flash(:error, gettext("Could not process GPX file."))}
    end
  end

  # FIX 2: Automatically create directory if it doesn't exist
  @impl true
  def handle_event("save_photos", _params, socket) do
    race = socket.assigns.race

    # Ensure the directory exists
    upload_dir = Path.join(["priv", "static", "uploads"])
    File.mkdir_p!(upload_dir)

    uploaded_files =
      consume_uploaded_entries(socket, :photos, fn %{path: path}, entry ->
        dest = Path.join([upload_dir, "#{entry.uuid}.#{ext(entry)}"])
        File.cp!(path, dest)
        {:ok, "/uploads/#{entry.uuid}.#{ext(entry)}"}
      end)

    for url <- uploaded_files do
      Racing.create_photo(%{race_id: race.id, image_path: url})
    end

    {:noreply,
     socket
     |> assign(:photos, Racing.list_race_photos(race.id))
     |> put_flash(:info, gettext("Memories saved!"))}
  end

  defp ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end

  # --- STANDARD HANDLERS ---

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

  # --- HELPERS ---

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

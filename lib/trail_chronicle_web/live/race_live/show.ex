defmodule TrailChronicleWeb.RaceLive.Show do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.{Racing}

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
           |> assign(:selected_photo, nil)
           |> assign(:pace, calculate_pace(race.distance_km, race.finish_time_seconds))
           |> assign(:current_path, "/races/#{id}")
           |> assign(:page_title, race.name)
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

  # --- EVENT HANDLERS ---

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save_gpx", _params, socket) do
    race = socket.assigns.race

    results =
      consume_uploaded_entries(socket, :gpx, fn %{path: path}, _entry ->
        case Racing.update_race_gpx(race, path) do
          {:ok, updated_race} -> {:ok, updated_race}
          {:error, _reason} -> {:ok, nil}
        end
      end)

    case List.first(results) do
      %TrailChronicle.Racing.Race{} = updated_race ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Route analyzed!"))
         |> assign(:race, updated_race)
         |> push_event("init_map", %{route: updated_race.route_data})}

      _ ->
        {:noreply, socket |> put_flash(:error, gettext("Failed to process GPX file."))}
    end
  end

  @impl true
  def handle_event("delete_gpx", _params, socket) do
    case Racing.delete_race_gpx(socket.assigns.race) do
      {:ok, updated_race} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Route removed successfully."))
         |> assign(:race, updated_race)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not remove route."))}
    end
  end

  @impl true
  def handle_event("save_photos", _params, socket) do
    race = socket.assigns.race
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

    updated_photos = Racing.list_race_photos(race.id)

    {:noreply,
     socket
     |> assign(:photos, updated_photos)
     |> put_flash(:info, gettext("Memories saved!"))}
  end

  # NEW: Delete Photo
  @impl true
  def handle_event("delete_photo", %{"id" => photo_id}, socket) do
    photo = Racing.get_photo!(photo_id)

    case Racing.delete_photo(photo) do
      {:ok, _} ->
        updated_photos = Racing.list_race_photos(socket.assigns.race.id)

        # If the deleted photo was open in lightbox, close it
        socket =
          if socket.assigns.selected_photo && socket.assigns.selected_photo.id == photo.id do
            assign(socket, :selected_photo, nil)
          else
            socket
          end

        {:noreply,
         socket
         |> assign(:photos, updated_photos)
         |> put_flash(:info, gettext("Photo removed."))}

      _ ->
        {:noreply, put_flash(socket, :error, "Failed to delete photo.")}
    end
  end

  # NEW: Set Cover
  @impl true
  def handle_event("set_cover", %{"id" => photo_id}, socket) do
    photo = Racing.get_photo!(photo_id)

    case Racing.set_cover_photo(socket.assigns.race, photo.image_path) do
      {:ok, updated_race} ->
        {:noreply,
         socket
         |> assign(:race, updated_race)
         |> put_flash(:info, gettext("Cover photo updated!"))}

      _ ->
        {:noreply, put_flash(socket, :error, "Failed to set cover.")}
    end
  end

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

  @impl true
  def handle_event("open_lightbox", %{"id" => photo_id}, socket) do
    photo = Enum.find(socket.assigns.photos, &(&1.id == photo_id))
    {:noreply, assign(socket, :selected_photo, photo)}
  end

  @impl true
  def handle_event("close_lightbox", _, socket) do
    {:noreply, assign(socket, :selected_photo, nil)}
  end

  @impl true
  def handle_event("next_photo", _, socket) do
    navigate_photo(socket, 1)
  end

  @impl true
  def handle_event("prev_photo", _, socket) do
    navigate_photo(socket, -1)
  end

  @impl true
  def handle_event("keydown", %{"key" => key}, socket) do
    case key do
      "ArrowRight" -> navigate_photo(socket, 1)
      "ArrowLeft" -> navigate_photo(socket, -1)
      "Escape" -> {:noreply, assign(socket, :selected_photo, nil)}
      _ -> {:noreply, socket}
    end
  end

  # --- HELPERS ---

  defp ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end

  defp navigate_photo(socket, step) do
    photos = socket.assigns.photos
    current = socket.assigns.selected_photo

    if current && length(photos) > 1 do
      current_idx = Enum.find_index(photos, &(&1.id == current.id))
      new_idx = Integer.mod(current_idx + step, length(photos))
      {:noreply, assign(socket, :selected_photo, Enum.at(photos, new_idx))}
    else
      {:noreply, socket}
    end
  end

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

  defp format_time(nil), do: "—"

  defp format_time(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    secs = rem(seconds, 60)
    "#{pad(hours)}:#{pad(minutes)}:#{pad(secs)}"
  end

  defp pad(num), do: String.pad_leading(to_string(num), 2, "0")
end

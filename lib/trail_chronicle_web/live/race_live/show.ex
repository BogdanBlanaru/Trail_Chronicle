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

          parsed_insight =
            if race.ai_insight do
              case Jason.decode(race.ai_insight) do
                {:ok, map} -> map
                _ -> nil
              end
            else
              nil
            end

          {:ok,
           socket
           |> assign(:race, race)
           |> assign(:ai_insight, parsed_insight)
           |> assign(:photos, photos)
           |> assign(:selected_photo, nil)
           |> assign(:map_lightbox, false)
           |> assign(:ai_loading, false)
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

  # --- NEW MAP LIGHTBOX HANDLERS ---

  @impl true
  def handle_event("open_map_lightbox", _, socket) do
    {:noreply, assign(socket, :map_lightbox, true)}
  end

  def handle_event("close_map_lightbox", _, socket) do
    {:noreply, assign(socket, :map_lightbox, false)}
  end

  # --- EXISTING HANDLERS (Unchanged) ---

  @impl true
  def handle_event("validate", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("save_gpx", _params, socket) do
    race = socket.assigns.race

    results =
      consume_uploaded_entries(socket, :gpx, fn %{path: path}, _entry ->
        case Racing.update_race_gpx(race, path) do
          {:ok, updated} -> {:ok, updated}
          {:error, _} -> {:ok, nil}
        end
      end)

    case List.first(results) do
      %Racing.Race{} = updated ->
        {:noreply,
         socket
         |> put_flash(:info, "Route analyzed!")
         |> assign(:race, updated)
         |> push_event("init_map", %{route: updated.route_data})}

      _ ->
        {:noreply, socket |> put_flash(:error, "Failed GPX.")}
    end
  end

  @impl true
  def handle_event("delete_gpx", _, socket) do
    case Racing.delete_race_gpx(socket.assigns.race) do
      {:ok, updated} ->
        {:noreply, socket |> assign(:race, updated) |> put_flash(:info, "Route removed.")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save_photos", _, socket) do
    race = socket.assigns.race
    upload_dir = Path.join(["priv", "static", "uploads"])
    File.mkdir_p!(upload_dir)

    consume_uploaded_entries(socket, :photos, fn %{path: path}, entry ->
      dest = Path.join([upload_dir, "#{entry.uuid}.#{ext(entry)}"])
      File.cp!(path, dest)
      url = "/uploads/#{entry.uuid}.#{ext(entry)}"
      Racing.create_photo(%{race_id: race.id, image_path: url})
      {:ok, url}
    end)

    {:noreply,
     socket
     |> assign(:photos, Racing.list_race_photos(race.id))
     |> put_flash(:info, "Photos saved!")}
  end

  @impl true
  def handle_event("set_cover", %{"id" => id}, socket) do
    photo = Racing.get_photo!(id)
    {:ok, updated} = Racing.set_cover_photo(socket.assigns.race, photo.image_path)
    {:noreply, assign(socket, :race, updated)}
  end

  @impl true
  def handle_event("delete_photo", %{"id" => id}, socket) do
    photo = Racing.get_photo!(id)
    Racing.delete_photo(photo)
    {:noreply, assign(socket, :photos, Racing.list_race_photos(socket.assigns.race.id))}
  end

  @impl true
  def handle_event("delete", _, socket) do
    Racing.delete_race(socket.assigns.race)
    {:noreply, redirect(socket, to: ~p"/races")}
  end

  @impl true
  def handle_event("switch-locale", %{"locale" => l}, socket),
    do: {:noreply, TrailChronicleWeb.LiveHelpers.handle_locale_switch(socket, l)}

  @impl true
  def handle_event("open_lightbox", %{"id" => id}, socket) do
    photo = Enum.find(socket.assigns.photos, &(&1.id == id))
    {:noreply, assign(socket, :selected_photo, photo)}
  end

  @impl true
  def handle_event("close_lightbox", _, socket),
    do: {:noreply, assign(socket, :selected_photo, nil)}

  @impl true
  def handle_event("next_photo", _, socket), do: navigate_photo(socket, 1)

  @impl true
  def handle_event("prev_photo", _, socket), do: navigate_photo(socket, -1)

  @impl true
  def handle_event("keydown", %{"key" => key}, socket) do
    case key do
      "ArrowRight" ->
        navigate_photo(socket, 1)

      "ArrowLeft" ->
        navigate_photo(socket, -1)

      "Escape" ->
        # Close whichever lightbox is open
        socket = assign(socket, :selected_photo, nil)
        {:noreply, assign(socket, :map_lightbox, false)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("generate_ai", _, socket) do
    race = socket.assigns.race

    # Queue background job instead of blocking
    %{race_id: race.id}
    |> TrailChronicle.Workers.AiAnalysisWorker.new()
    |> Oban.insert()

    {:noreply,
     socket
     |> assign(:ai_loading, true)
     |> put_flash(
       :info,
       gettext("AI analysis started in background. Refresh in a few moments...")
     )}
  end

  @impl true
  def handle_info(:run_ai_analysis, socket) do
    case Racing.save_ai_insight(socket.assigns.race) do
      {:ok, updated_race} ->
        {:ok, parsed} = Jason.decode(updated_race.ai_insight)

        {:noreply,
         socket
         |> assign(:race, updated_race)
         |> assign(:ai_insight, parsed)
         |> assign(:ai_loading, false)
         |> put_flash(:info, gettext("Analysis complete!"))}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:ai_loading, false)
         |> put_flash(:error, gettext("Coach is currently offline."))}
    end
  end

  # --- HELPERS ---
  defp ext(entry), do: hd(MIME.extensions(entry.client_type))

  defp navigate_photo(socket, step) do
    photos = socket.assigns.photos
    current = socket.assigns.selected_photo

    if current && length(photos) > 1 do
      idx = Enum.find_index(photos, &(&1.id == current.id))
      new_idx = Integer.mod(idx + step, length(photos))
      {:noreply, assign(socket, :selected_photo, Enum.at(photos, new_idx))}
    else
      {:noreply, socket}
    end
  end

  defp format_time(nil), do: "—"
  defp format_time(s), do: "#{div(s, 3600)}:#{pad(div(rem(s, 3600), 60))}:#{pad(rem(s, 60))}"
  defp pad(n), do: String.pad_leading("#{n}", 2, "0")

  defp calculate_pace(d, t) do
    if d && t && Decimal.to_float(d) > 0 do
      pace = t / Decimal.to_float(d)
      "#{div(trunc(pace), 60)}:#{pad(rem(trunc(pace), 60))}"
    end
  end
end

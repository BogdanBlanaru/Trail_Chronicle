defmodule TrailChronicleWeb.RaceLive.Form do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.{Accounts, Racing}
  alias TrailChronicle.Racing.Race

  @impl true
  def mount(params, _session, socket) do
    athlete = Accounts.get_athlete_by_email("bogdan@example.com")

    if athlete do
      {:ok,
       socket
       |> assign(:athlete, athlete)
       |> assign(:current_path, socket.assigns.live_action)
       |> apply_action(socket.assigns.live_action, params)}
    else
      {:ok, redirect(socket, to: ~p"/")}
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add New Race")
    |> assign(:race, %Race{})
    |> assign(:changeset, Racing.change_race(%Race{}))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    race = Racing.get_race!(id)

    socket
    |> assign(:page_title, "Edit Race")
    |> assign(:race, race)
    |> assign(:changeset, Racing.change_race(race))
  end

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

  defp save_race(socket, :new, race_params) do
    case Racing.create_race(socket.assigns.athlete, race_params) do
      {:ok, race} ->
        {:noreply,
         socket
         |> put_flash(:info, "Race created successfully!")
         |> redirect(to: ~p"/races/#{race.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp save_race(socket, :edit, race_params) do
    case Racing.update_race(socket.assigns.race, race_params) do
      {:ok, race} ->
        {:noreply,
         socket
         |> put_flash(:info, "Race updated successfully!")
         |> redirect(to: ~p"/races/#{race.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp format_time_input(nil), do: ""

  defp format_time_input(seconds) when is_integer(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    secs = rem(seconds, 60)

    "#{pad(hours)}:#{pad(minutes)}:#{pad(secs)}"
  end

  defp format_time_input(_), do: ""

  defp pad(num), do: String.pad_leading(to_string(num), 2, "0")
end

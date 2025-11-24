defmodule TrailChronicleWeb.GearLive.Index do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.Racing
  alias TrailChronicle.Racing.Shoe

  @impl true
  def mount(_params, _session, socket) do
    athlete = socket.assigns.current_athlete

    if athlete do
      # Separate active and retired shoes
      all_shoes = Racing.list_shoes(athlete)
      {active, retired} = Enum.split_with(all_shoes, &(!&1.is_retired))

      {:ok,
       socket
       |> assign(:active_shoes, active)
       |> assign(:retired_shoes, retired)
       |> assign(:show_modal, false)
       |> assign(:editing_shoe, nil)
       |> assign(:form, nil)
       |> assign(:current_path, "/gear")
       |> assign(:page_title, gettext("Gear Closet"))}
    else
      {:ok, redirect(socket, to: ~p"/athletes/log_in")}
    end
  end

  @impl true
  def handle_event("new_shoe", _, socket) do
    changeset = Racing.change_shoe(%Shoe{})

    {:noreply,
     socket
     |> assign(:show_modal, true)
     |> assign(:editing_shoe, %Shoe{})
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("edit_shoe", %{"id" => id}, socket) do
    shoe = Racing.get_shoe!(id)
    changeset = Racing.change_shoe(shoe)

    {:noreply,
     socket
     |> assign(:show_modal, true)
     |> assign(:editing_shoe, shoe)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("retire_shoe", %{"id" => id}, socket) do
    shoe = Racing.get_shoe!(id)
    {:ok, _} = Racing.retire_shoe(shoe)
    {:noreply, refresh_list(socket)}
  end

  @impl true
  def handle_event("delete_shoe", %{"id" => id}, socket) do
    shoe = Racing.get_shoe!(id)
    Racing.delete_shoe(shoe)
    {:noreply, refresh_list(socket)}
  end

  @impl true
  def handle_event("validate", %{"shoe" => params}, socket) do
    changeset =
      socket.assigns.editing_shoe
      |> Racing.change_shoe(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"shoe" => params}, socket) do
    result =
      if socket.assigns.editing_shoe.id do
        Racing.update_shoe(socket.assigns.editing_shoe, params)
      else
        # FIX: Passed full athlete struct instead of just ID
        Racing.create_shoe(socket.assigns.current_athlete, params)
      end

    case result do
      {:ok, _shoe} ->
        {:noreply,
         socket
         |> put_flash(:info, "Gear closet updated.")
         |> assign(:show_modal, false)
         |> refresh_list()}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  # Needed for Nav Component
  def handle_event("switch-locale", %{"locale" => l}, socket),
    do: {:noreply, TrailChronicleWeb.LiveHelpers.handle_locale_switch(socket, l)}

  defp refresh_list(socket) do
    all = Racing.list_shoes(socket.assigns.current_athlete)
    {active, retired} = Enum.split_with(all, &(!&1.is_retired))
    socket |> assign(active_shoes: active, retired_shoes: retired)
  end

  defp progress_color(current, limit) do
    percent = Decimal.to_float(current) / limit * 100

    cond do
      percent > 100 -> "bg-red-500"
      percent > 75 -> "bg-amber-500"
      true -> "bg-emerald-500"
    end
  end
end

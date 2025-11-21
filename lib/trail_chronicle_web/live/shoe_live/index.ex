defmodule TrailChronicleWeb.ShoeLive.Index do
  use TrailChronicleWeb, :live_view
  alias TrailChronicle.Racing
  alias TrailChronicle.Racing.Shoe

  def mount(_params, _session, socket) do
    athlete = socket.assigns.current_athlete

    if athlete do
      shoes = Racing.list_shoes(athlete)

      {:ok,
       socket
       |> assign(:shoes, shoes)
       |> assign(:page_title, "Gear Garage")
       |> assign(:current_path, "/shoes")
       |> assign(:show_form, false)
       |> assign(:form, to_form(Racing.change_shoe(%Shoe{})))}
    else
      {:ok, redirect(socket, to: ~p"/athletes/log_in")}
    end
  end

  def handle_event("toggle_form", _, socket) do
    {:noreply, assign(socket, :show_form, !socket.assigns.show_form)}
  end

  def handle_event("validate", %{"shoe" => params}, socket) do
    changeset =
      %Shoe{}
      |> Racing.change_shoe(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"shoe" => params}, socket) do
    case Racing.create_shoe(socket.assigns.current_athlete, params) do
      {:ok, _shoe} ->
        shoes = Racing.list_shoes(socket.assigns.current_athlete)

        {:noreply,
         socket
         |> assign(:shoes, shoes)
         |> assign(:show_form, false)
         |> put_flash(:info, "New kicks added!")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("retire", %{"id" => id}, socket) do
    shoe = Racing.get_shoe!(id)
    Racing.retire_shoe(shoe)
    {:noreply, assign(socket, :shoes, Racing.list_shoes(socket.assigns.current_athlete))}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    shoe = Racing.get_shoe!(id)
    Racing.delete_shoe(shoe)
    {:noreply, assign(socket, :shoes, Racing.list_shoes(socket.assigns.current_athlete))}
  end
end

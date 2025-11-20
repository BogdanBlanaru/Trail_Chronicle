defmodule TrailChronicleWeb.PlaceholderLive do
  use TrailChronicleWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, get_page_title(socket.assigns.live_action))
     |> assign(:current_path, get_current_path(socket.assigns.live_action))}
  end

  def handle_event("switch-locale", %{"locale" => locale}, socket) do
    {:noreply, TrailChronicleWeb.LiveHelpers.handle_locale_switch(socket, locale)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 flex items-center justify-center px-4">
      <div class="max-w-md w-full text-center">
        <div class="mb-8">
          <span class="text-8xl">🚧</span>
        </div>
        <h1 class="text-3xl font-bold text-gray-900 mb-4">{@page_title}</h1>
        <p class="text-xl text-gray-600 mb-8">{gettext("Coming Soon")}</p>
        <p class="text-gray-500 mb-8">{gettext("This feature is under development")}</p>
        <.link navigate={~p"/"} class="text-blue-600 hover:text-blue-700 font-medium">
          ← {gettext("Back to Dashboard")}
        </.link>
      </div>
    </div>
    """
  end

  defp get_page_title(:calendar), do: gettext("Calendar View")
  defp get_page_title(:stats), do: gettext("Statistics Dashboard")
  defp get_page_title(_), do: gettext("Coming Soon")

  defp get_current_path(:calendar), do: "/calendar"
  defp get_current_path(:stats), do: "/stats"
  defp get_current_path(_), do: "/"
end

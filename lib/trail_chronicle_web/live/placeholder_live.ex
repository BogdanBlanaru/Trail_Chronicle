defmodule TrailChronicleWeb.PlaceholderLive do
  use TrailChronicleWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    athlete = TrailChronicle.Accounts.get_athlete_by_email("bogdan@example.com")

    {:ok,
     socket
     |> assign(:athlete, athlete)
     |> assign(:current_path, socket.assigns.live_action |> to_string())
     |> assign(:page_title, "Coming Soon")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center min-h-screen">
      <div class="text-center">
        <h1 class="text-4xl font-bold text-gray-900 mb-4">🚧 Coming Soon</h1>

        <p class="text-gray-600 mb-8">This feature is under construction.</p>

        <%= live_redirect to: ~p"/", class: "text-blue-600 hover:text-blue-700 font-medium" do %>
          ← Back to Dashboard
        <% end %>
      </div>
    </div>
    """
  end
end

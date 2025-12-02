defmodule TrailChronicleWeb.AthleteConfirmationInstructionsLive do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.Accounts

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <div class="text-center">
          <span class="text-6xl">📨</span>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            {gettext("Resend confirmation instructions")}
          </h2>
        </div>
      </div>

      <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-white py-8 px-4 shadow-2xl sm:rounded-2xl sm:px-10">
          <.simple_form for={@form} id="resend_confirmation_form" phx-submit="send_instructions">
            <.input field={@form[:email]} type="email" placeholder={gettext("Email")} required />
            <:actions>
              <.button phx-disable-with={gettext("Sending...")} class="w-full">
                {gettext("Resend confirmation instructions")}
              </.button>
            </:actions>
          </.simple_form>

          <p class="mt-4 text-center text-sm">
            <.link href={~p"/athletes/register"} class="text-blue-600 hover:text-blue-500">
              {gettext("Register")}
            </.link>
            |
            <.link href={~p"/athletes/log_in"} class="text-blue-600 hover:text-blue-500">
              {gettext("Log in")}
            </.link>
          </p>
        </div>
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    locale = params["locale"] || Gettext.get_locale(TrailChronicleWeb.Gettext)
    Gettext.put_locale(TrailChronicleWeb.Gettext, locale)

    {:ok,
     assign(socket,
       form: to_form(%{}, as: "athlete"),
       page_title: gettext("Resend confirmation instructions"),
       locale: locale
     )}
  end

  def handle_params(_params, url, socket) do
    uri = URI.parse(url)
    current_path = if uri.query, do: uri.path <> "?" <> uri.query, else: uri.path
    {:noreply, assign(socket, :current_path, current_path)}
  end

  def handle_event("send_instructions", %{"athlete" => %{"email" => email}}, socket) do
    if athlete = Accounts.get_athlete_by_email(email) do
      Accounts.deliver_athlete_confirmation_instructions(
        athlete,
        &url(~p"/athletes/confirm/#{&1}")
      )
    end

    info =
      "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end

  def handle_event("switch-locale", %{"locale" => locale}, socket) do
    Gettext.put_locale(TrailChronicleWeb.Gettext, locale)

    path = socket.assigns[:current_path] || ~p"/athletes/confirm"
    uri = URI.parse(path)
    query = URI.decode_query(uri.query || "") |> Map.put("locale", locale)
    final_path = %{uri | query: URI.encode_query(query)} |> URI.to_string()

    {:noreply, push_navigate(socket, to: final_path)}
  end
end

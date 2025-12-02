defmodule TrailChronicleWeb.AthleteForgotPasswordLive do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.Accounts

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <div class="text-center">
          <span class="text-6xl">🔐</span>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            {gettext("Forgot your password?")}
          </h2>

          <p class="mt-2 text-center text-sm text-gray-600">
            {gettext("We'll send a password reset link to your inbox")}
          </p>
        </div>
      </div>

      <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-white py-8 px-4 shadow-2xl sm:rounded-2xl sm:px-10">
          <.simple_form for={@form} id="reset_password_form" phx-submit="send_email">
            <.input field={@form[:email]} type="email" placeholder={gettext("Email")} required />
            <:actions>
              <.button phx-disable-with={gettext("Sending...")} class="w-full">
                {gettext("Send password reset instructions")}
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
    # Determine locale from params or current process default
    locale = params["locale"] || Gettext.get_locale(TrailChronicleWeb.Gettext)
    Gettext.put_locale(TrailChronicleWeb.Gettext, locale)

    {:ok,
     assign(socket,
       form: to_form(%{}, as: "athlete"),
       page_title: gettext("Forgot your password?"),
       # Assign locale so the layout can access @locale
       locale: locale
     )}
  end

  def handle_params(_params, url, socket) do
    uri = URI.parse(url)
    current_path = if uri.query, do: uri.path <> "?" <> uri.query, else: uri.path
    {:noreply, assign(socket, :current_path, current_path)}
  end

  def handle_event("send_email", %{"athlete" => %{"email" => email}}, socket) do
    if athlete = Accounts.get_athlete_by_email(email) do
      Accounts.deliver_athlete_reset_password_instructions(
        athlete,
        &url(~p"/athletes/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end

  def handle_event("switch-locale", %{"locale" => locale}, socket) do
    Gettext.put_locale(TrailChronicleWeb.Gettext, locale)

    path = socket.assigns[:current_path] || ~p"/athletes/reset_password"
    uri = URI.parse(path)
    query = URI.decode_query(uri.query || "") |> Map.put("locale", locale)
    final_path = %{uri | query: URI.encode_query(query)} |> URI.to_string()

    {:noreply, push_navigate(socket, to: final_path)}
  end
end

defmodule TrailChronicleWeb.AthleteConfirmationLive do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.Accounts

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <div class="text-center">
          <span class="text-6xl">✉️</span>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            {gettext("Confirm your account")}
          </h2>
        </div>
      </div>

      <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-white py-8 px-4 shadow-2xl sm:rounded-2xl sm:px-10">
          <.simple_form for={@form} id="confirmation_form" phx-submit="confirm_account">
            <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
            <:actions>
              <.button phx-disable-with={gettext("Confirming...")} class="w-full">
                {gettext("Confirm my account")}
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
    # Locale logic
    locale = params["locale"] || Gettext.get_locale(TrailChronicleWeb.Gettext)
    Gettext.put_locale(TrailChronicleWeb.Gettext, locale)

    token = params["token"]
    form = to_form(%{"token" => token}, as: "athlete")

    {:ok, assign(socket, form: form, page_title: gettext("Confirm Account"), locale: locale),
     temporary_assigns: [form: nil]}
  end

  def handle_params(_params, url, socket) do
    uri = URI.parse(url)
    current_path = if uri.query, do: uri.path <> "?" <> uri.query, else: uri.path
    {:noreply, assign(socket, :current_path, current_path)}
  end

  # Do not log in the athlete after confirmation to avoid a
  # leaked token giving the athlete access to the account.
  def handle_event("confirm_account", %{"athlete" => %{"token" => token}}, socket) do
    case Accounts.confirm_athlete(token) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Athlete confirmed successfully.")
         |> redirect(to: ~p"/")}

      :error ->
        # If there is a current athlete and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the athlete themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_athlete: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/")}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, "Athlete confirmation link is invalid or it has expired.")
             |> redirect(to: ~p"/")}
        end
    end
  end

  def handle_event("switch-locale", %{"locale" => locale}, socket) do
    Gettext.put_locale(TrailChronicleWeb.Gettext, locale)

    # Fallback, though usually has token
    path = socket.assigns[:current_path] || ~p"/athletes/confirm"
    uri = URI.parse(path)
    query = URI.decode_query(uri.query || "") |> Map.put("locale", locale)
    final_path = %{uri | query: URI.encode_query(query)} |> URI.to_string()

    {:noreply, push_navigate(socket, to: final_path)}
  end
end

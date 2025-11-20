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

  def mount(%{"token" => token}, _session, socket) do
    form = to_form(%{"token" => token}, as: "athlete")

    {:ok, assign(socket, form: form, page_title: gettext("Confirm Account")),
     temporary_assigns: [form: nil]}
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
end

defmodule TrailChronicleWeb.AthleteResetPasswordLive do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.Accounts

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <div class="text-center">
          <span class="text-6xl">🔑</span>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            {gettext("Reset password")}
          </h2>
        </div>
      </div>

      <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-white py-8 px-4 shadow-2xl sm:rounded-2xl sm:px-10">
          <.simple_form
            for={@form}
            id="reset_password_form"
            phx-submit="reset_password"
            phx-change="validate"
          >
            <.error :if={@form.errors != []}>
              {gettext("Oops, something went wrong! Please check the errors below.")}
            </.error>

            <.input field={@form[:password]} type="password" label={gettext("New password")} required />
            <.input
              field={@form[:password_confirmation]}
              type="password"
              label={gettext("Confirm new password")}
              required
            />
            <:actions>
              <.button phx-disable-with={gettext("Resetting...")} class="w-full">
                {gettext("Reset password")}
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
    socket = assign_athlete_and_token(socket, params)

    form_source =
      case socket.assigns do
        %{athlete: athlete} ->
          Accounts.change_athlete_password(athlete)

        _ ->
          %{}
      end

    {:ok, assign_form(socket, form_source), temporary_assigns: [form: nil]}
  end

  # Do not log in the athlete after reset password to avoid a
  # leaked token giving the athlete access to the account.
  def handle_event("reset_password", %{"athlete" => athlete_params}, socket) do
    case Accounts.reset_athlete_password(socket.assigns.athlete, athlete_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully.")
         |> redirect(to: ~p"/athletes/log_in")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"athlete" => athlete_params}, socket) do
    changeset = Accounts.change_athlete_password(socket.assigns.athlete, athlete_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_athlete_and_token(socket, %{"token" => token}) do
    if athlete = Accounts.get_athlete_by_reset_password_token(token) do
      assign(socket, athlete: athlete, token: token)
    else
      socket
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/")
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "athlete"))
  end
end

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

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       form: to_form(%{}, as: "athlete"),
       page_title: gettext("Resend confirmation instructions")
     )}
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
end

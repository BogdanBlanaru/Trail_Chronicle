defmodule TrailChronicleWeb.AthleteRegistrationLive do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.Accounts
  alias TrailChronicle.Accounts.Athlete

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <div class="text-center">
          <span class="text-6xl">🏔️</span>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            {gettext("Create your account")}
          </h2>

          <p class="mt-2 text-center text-sm text-gray-600">
            {gettext("Or")}
            <.link
              navigate={~p"/athletes/log_in"}
              class="font-medium text-blue-600 hover:text-blue-500"
            >
              {gettext("sign in to your account")}
            </.link>
          </p>
        </div>
      </div>

      <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-white py-8 px-4 shadow-2xl sm:rounded-2xl sm:px-10">
          <.simple_form
            for={@form}
            id="registration_form"
            phx-submit="save"
            phx-change="validate"
            phx-trigger-action={@trigger_submit}
            action={~p"/athletes/log_in?_action=registered"}
            method="post"
          >
            <.error :if={@check_errors}>
              {gettext("Oops, something went wrong! Please check the errors below.")}
            </.error>
            <.input field={@form[:first_name]} type="text" label={gettext("First Name")} required />
            <.input field={@form[:last_name]} type="text" label={gettext("Last Name")} required />
            <.input field={@form[:email]} type="email" label={gettext("Email")} required />
            <.input field={@form[:password]} type="password" label={gettext("Password")} required />
            <:actions>
              <.button phx-disable-with={gettext("Creating account...")} class="w-full">
                {gettext("Create an account")}
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_athlete_registration(%Athlete{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign(:page_title, gettext("Register"))
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"athlete" => athlete_params}, socket) do
    case Accounts.register_athlete(athlete_params) do
      {:ok, athlete} ->
        {:ok, _} =
          Accounts.deliver_athlete_confirmation_instructions(
            athlete,
            &url(~p"/athletes/confirm/#{&1}")
          )

        changeset = Accounts.change_athlete_registration(athlete)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"athlete" => athlete_params}, socket) do
    changeset = Accounts.change_athlete_registration(%Athlete{}, athlete_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "athlete")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end

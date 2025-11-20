defmodule TrailChronicleWeb.AthleteSettingsLive do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.Accounts

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 py-8">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-gray-900">{gettext("Account Settings")}</h1>

          <p class="mt-2 text-sm text-gray-600">
            {gettext("Manage your account security and preferences")}
          </p>
        </div>

        <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <!-- Change Email Card -->
          <div class="bg-white rounded-lg shadow-md p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center">
              <span class="mr-2">📧</span> {gettext("Change Email")}
            </h3>

            <.simple_form
              for={@email_form}
              id="email_form"
              phx-submit="update_email"
              phx-change="validate_email"
            >
              <.input field={@email_form[:email]} type="email" label={gettext("Email")} required />
              <.input
                field={@email_form[:current_password]}
                name="current_password"
                id="current_password_for_email"
                type="password"
                label={gettext("Current password")}
                value={@email_form_current_password}
                required
              />
              <:actions>
                <.button phx-disable-with={gettext("Changing...")}>{gettext("Change Email")}</.button>
              </:actions>
            </.simple_form>
          </div>
          <!-- Change Password Card -->
          <div class="bg-white rounded-lg shadow-md p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center">
              <span class="mr-2">🔒</span> {gettext("Change Password")}
            </h3>

            <.simple_form
              for={@password_form}
              id="password_form"
              action={~p"/athletes/log_in?_action=password_updated"}
              method="post"
              phx-change="validate_password"
              phx-submit="update_password"
              phx-trigger-action={@trigger_submit}
            >
              <input
                name={@password_form[:email].name}
                type="hidden"
                id="hidden_athlete_email"
                value={@current_email}
              />
              <.input
                field={@password_form[:password]}
                type="password"
                label={gettext("New password")}
                required
              />
              <.input
                field={@password_form[:password_confirmation]}
                type="password"
                label={gettext("Confirm new password")}
                required
              />
              <.input
                field={@password_form[:current_password]}
                name="current_password"
                type="password"
                label={gettext("Current password")}
                id="current_password_for_password"
                value={@current_password}
                required
              />
              <:actions>
                <.button phx-disable-with={gettext("Changing...")}>
                  {gettext("Change Password")}
                </.button>
              </:actions>
            </.simple_form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_athlete_email(socket.assigns.current_athlete, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/athletes/settings")}
  end

  def mount(_params, _session, socket) do
    athlete = socket.assigns.current_athlete
    email_changeset = Accounts.change_athlete_email(athlete)
    password_changeset = Accounts.change_athlete_password(athlete)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, athlete.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:page_title, gettext("Settings"))

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "athlete" => athlete_params} = params

    email_form =
      socket.assigns.current_athlete
      |> Accounts.change_athlete_email(athlete_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "athlete" => athlete_params} = params
    athlete = socket.assigns.current_athlete

    case Accounts.apply_athlete_email(athlete, password, athlete_params) do
      {:ok, applied_athlete} ->
        Accounts.deliver_athlete_update_email_instructions(
          applied_athlete,
          athlete.email,
          &url(~p"/athletes/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "athlete" => athlete_params} = params

    password_form =
      socket.assigns.current_athlete
      |> Accounts.change_athlete_password(athlete_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "athlete" => athlete_params} = params
    athlete = socket.assigns.current_athlete

    case Accounts.update_athlete_password(athlete, password, athlete_params) do
      {:ok, athlete} ->
        password_form =
          athlete
          |> Accounts.change_athlete_password(athlete_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end

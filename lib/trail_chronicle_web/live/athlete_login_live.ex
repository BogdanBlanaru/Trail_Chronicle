defmodule TrailChronicleWeb.AthleteLoginLive do
  use TrailChronicleWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <div class="text-center">
          <span class="text-6xl">🏔️</span>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            {gettext("Sign in to your account")}
          </h2>

          <p class="mt-2 text-center text-sm text-gray-600">
            {gettext("Or")}
            <.link
              navigate={~p"/athletes/register"}
              class="font-medium text-blue-600 hover:text-blue-500"
            >
              {gettext("create a new account")}
            </.link>
          </p>
        </div>
      </div>

      <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-white py-8 px-4 shadow-2xl sm:rounded-2xl sm:px-10">
          <.simple_form for={@form} id="login_form" action={~p"/athletes/log_in"} phx-update="ignore">
            <.input field={@form[:email]} type="email" label={gettext("Email")} required />
            <.input field={@form[:password]} type="password" label={gettext("Password")} required />
            <:actions>
              <.input
                field={@form[:remember_me]}
                type="checkbox"
                label={gettext("Keep me logged in")}
              />
              <.link
                href={~p"/athletes/reset_password"}
                class="text-sm font-semibold text-blue-600 hover:text-blue-500"
              >
                {gettext("Forgot your password?")}
              </.link>
            </:actions>

            <:actions>
              <.button phx-disable-with={gettext("Signing in...")} class="w-full">
                {gettext("Sign in")} <span aria-hidden="true">→</span>
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "athlete")

    {:ok, assign(socket, form: form, page_title: gettext("Log in")),
     temporary_assigns: [form: form]}
  end
end

defmodule CarrierWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use CarrierWeb, :controller
      use CarrierWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt sitemap.xml)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import CarrierWeb.Gettext
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        namespace: CarrierWeb,
        formats: [:html, :json],
        layouts: [html: {CarrierWeb.Layouts, :app}]

      import Plug.Conn
      import CarrierWeb.Gettext

      unquote(verified_routes())
    end
  end

  def plug do
    quote do
      import Plug.Conn

      unquote(verified_routes())
    end
  end

  # TODO: remove
  def view do
    quote do
      use Phoenix.View,
        root: "lib/carrier_web/templates",
        namespace: CarrierWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(html_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView
      require Logger
      alias Carrier.Obfuscatable

      on_mount(CarrierWeb.FlashHook)

      unquote(html_helpers())
      unquote(live_helpers())
    end
  end

  def live_hook do
    quote do
      import Phoenix.LiveView

      unquote(html_helpers())
      unquote(live_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent
      import CarrierWeb.AssignHelper

      import CarrierWeb.FlashHook, only: [push_flash: 4]

      unquote(html_helpers())
      unquote(live_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: CarrierWeb.Endpoint,
        router: CarrierWeb.Router,
        statics: CarrierWeb.static_paths()
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      # TODO: change to `import Phoenix.HTML`
      use Phoenix.HTML
      # Core UI components and translation
      import CarrierWeb.{CoreComponents, MainComponents}
      import CarrierWeb.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      import CarrierWeb.LiveHelpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      alias CarrierWeb.Components.{Icon, Search}

      alias Carrier.Const

      # TODO: remove
      import CarrierWeb.ErrorHelpers
      import Phoenix.Component

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  defp live_helpers() do
    quote do
      import CarrierWeb.{AssignHelper, AnalyticsHelper}

      def put_flash_for(socket, kind, message, opts \\ []) do
        timeout = opts |> Keyword.get(:timeout, :infinity)

        socket = Phoenix.LiveView.put_flash(socket, kind, message)

        case timeout do
          :infinity ->
            nil

          timeout when is_integer(timeout) ->
            Process.send_after(self(), :clear_flash, timeout)
        end

        socket
      end

      def handle_info(:clear_flash, socket) do
        {:noreply, clear_flash(socket)}
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

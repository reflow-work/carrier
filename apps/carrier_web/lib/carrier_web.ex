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
      use Phoenix.Router

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
      use Phoenix.Controller, namespace: CarrierWeb

      import Plug.Conn
      import CarrierWeb.Gettext
      alias CarrierWeb.Router.Helpers, as: Routes
    end
  end

  def plug do
    quote do
      import Plug.Conn
      alias CarrierWeb.Router.Helpers, as: Routes
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
      unquote(html_helper())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView, layout: {CarrierWeb.LayoutView, :live}

      require Logger
      # TODO: remove
      import CarrierWeb.LiveHelpers
      import CarrierWeb.AnalyticsHelper
      alias Phoenix.LiveView.JS

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

      unquote(html_helper())
    end
  end

  def live_hook do
    quote do
      import Phoenix.LiveView
      import CarrierWeb.AnalyticsHelper
      import CarrierWeb.ChanneltalkHelper

      unquote(html_helper())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helper())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(html_helper())
    end
  end

  defp html_helper do
    quote do
      # HTML escaping functionality
      use Phoenix.HTML
      # Core UI components and translation
      # TODO: uncomment
      # import CarrierWeb.CoreComponents
      import CarrierWeb.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      # TODO: remove
      import CarrierWeb.ErrorHelpers
      alias CarrierWeb.Router.Helpers, as: Routes
      import Phoenix.Component
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

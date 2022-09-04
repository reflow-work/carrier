defmodule CarrierWeb.Router do
  use CarrierWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {CarrierWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Without Auth
  scope "/", CarrierWeb do
    pipe_through :browser

    get "/health", HealthController, :index
    get "/login", AuthController, :login
    get "/logout", AuthController, :logout

    scope "/auth" do
      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
  end

  # With Auth
  scope "/", CarrierWeb do
    pipe_through :browser

    live_session :user, on_mount: CarrierWeb.UserHook do
      live "/integrations/new", IntegrationLive.New, :new
      live "/data-sources/new", DataSourceLive.New, :new
      live "/reports", ReportLive.Index, :index
      live "/reports/:id/delete", ReportLive.Index, :delete
      live "/reports/new", ReportLive.New, :new
      live "/settings", SettingsLive, :index
    end
  end

  forward "/", ReverseProxyPlug,
    upstream: "https://reflow-service.webflow.io",
    response_mode: :buffer,
    client_options: [
      tesla_client: Tesla.client([])
    ]

  # Other scopes may use custom stacks.
  # scope "/api", CarrierWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CarrierWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

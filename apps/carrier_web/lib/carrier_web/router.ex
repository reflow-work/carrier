defmodule CarrierWeb.Router do
  use CarrierWeb, :router
  import Phoenix.LiveView.Router

  @content_security_policy [
                             "default-src 'self'",
                             "script-src 'self' 'unsafe-inline' cdn.channel.io js.tosspayments.com js.sentry-cdn.com www.googletagmanager.com web-sdk.smartlook.com blob:",
                             "style-src 'self' 'unsafe-inline'",
                             "connect-src 'self' api.channel.io api.tosspayments.com event.tosspayments.com cf.channel.io gw.channel.io www.google-analytics.com *.smartlook.cloud *.amplitude.com wss://*.channel.io",
                             "frame-src 'self' api.tosspayments.com *.tosspayments.com demo.arcade.software",
                             "img-src 'self' cf.channel.io data:",
                             "media-src cdn.channel.io"
                           ]
                           |> Enum.join("; ")

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {CarrierWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" => @content_security_policy
    }
  end

  pipeline :landing do
    plug :put_layout, html: {CarrierWeb.Layouts, :landing}
  end

  pipeline :auth_user do
    plug CarrierWeb.AuthPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  get "/health", CarrierWeb.HealthController, :index

  # Without Auth
  scope "/", CarrierWeb do
    pipe_through [:browser, :landing]

    live_session :router,
      layout: {CarrierWeb.Layouts, :landing},
      on_mount: [
        CarrierWeb.TimezoneHook,
        CarrierWeb.AnalyticsHook,
        CarrierWeb.ChanneltalkHook
      ] do
      live "/", HomeLive, :index
      live "/pricing", PricingLive
    end
  end

  # Auth
  scope "/", CarrierWeb do
    pipe_through :browser

    get "/login", AuthController, :login
    get "/logout", AuthController, :logout

    scope "/auth" do
      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
  end

  # With Auth
  scope "/app", CarrierWeb.App, as: :app do
    pipe_through [:browser, :auth_user]

    live_session :user,
      on_mount: [
        CarrierWeb.UserHook,
        CarrierWeb.TimezoneHook,
        CarrierWeb.AnalyticsHook,
        CarrierWeb.ChanneltalkHook,
        CarrierWeb.OnboardingHook
      ] do
      live "/onboarding", OnboardingLive.Index, :index
      live "/subscriptions/new", SubscriptionLive.New
      live "/subscriptions/done", SubscriptionLive.Done
      live "/integrations/new", IntegrationLive.New, :new
      live "/data-sources", DataSourceLive.Index, :index
      live "/data-sources/new", DataSourceLive.New, :new
      live "/reports", ReportLive.Index, :index
      live "/reports/:id/delete", ReportLive.Index, :delete
      live "/reports/new", ReportLive.New, :new
      live "/reports/new2", ReportLive.New2, :new
      live "/reports/:id/edit", ReportLive.New, :edit
      live "/report_logs", ReportLogLive.Index, :index
      live "/settings", SettingsLive, :index
    end

    get "/payment/callback/toss-payments", PaymentController, :toss_payments_callback
  end

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

  forward "/", CarrierWeb.FallbackPlug
end

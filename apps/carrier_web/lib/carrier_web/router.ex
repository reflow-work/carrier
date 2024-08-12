defmodule CarrierWeb.Router do
  use CarrierWeb, :router
  import Phoenix.LiveView.Router

  # @content_security_policy [
  #                            "default-src 'self'",
  #                            "script-src 'self' 'unsafe-inline' cdn.channel.io js.tosspayments.com js.sentry-cdn.com www.googletagmanager.com web-sdk.smartlook.com blob:",
  #                            "style-src 'self' 'unsafe-inline'",
  #                            "connect-src 'self' api.channel.io api.tosspayments.com event.tosspayments.com cf.channel.io gw.channel.io www.google-analytics.com *.smartlook.cloud *.amplitude.com wss://*.channel.io",
  #                            "frame-src 'self' api.tosspayments.com *.tosspayments.com demo.arcade.software",
  #                            "img-src 'self' cf.channel.io data:",
  #                            "media-src cdn.channel.io"
  #                          ]
  #                          |> Enum.join("; ")

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {CarrierWeb.Layouts, :root}
    plug :protect_from_forgery

    # plug :put_secure_browser_headers, %{
    #   "content-security-policy" => @content_security_policy
    # }
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

  pipeline :auth_api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_live_flash
  end

  pipeline :auth_admin do
    plug :admin_basic_auth
  end

  get "/health", CarrierWeb.HealthController, :index

  # Without Auth
  scope "/", CarrierWeb do
    pipe_through([:browser, :landing])

    live_session :router,
      layout: {CarrierWeb.Layouts, :landing},
      on_mount: [
        CarrierWeb.TimezoneHook,
        CarrierWeb.AnalyticsHook,
        CarrierWeb.ChanneltalkHook
      ] do
      live("/", HomeLive)
      live("/login", LoginLive)
      live("/invite", InviteLive)
      live("/blog", Blog.PostLive.Index)
      live("/blog/:language", Blog.PostLive.Index)
      live("/blog/:language/:slug", Blog.PostLive.Show)
    end
  end

  # Auth
  scope "/", CarrierWeb do
    pipe_through(:browser)

    get "/logout", AuthController, :logout
  end

  scope "/", CarrierWeb do
    pipe_through(:auth_api)

    post "/auth/google/callback", AuthController, :google_callback
  end

  # With Auth
  scope "/app", CarrierWeb.App, as: :app do
    pipe_through([:browser, :auth_user])

    live_session :app,
      layout: {CarrierWeb.Layouts, :live},
      on_mount: [
        CarrierWeb.UserHook,
        CarrierWeb.SubscriptionHook,
        CarrierWeb.TimezoneHook,
        CarrierWeb.AnalyticsHook,
        CarrierWeb.ChanneltalkHook,
        CarrierWeb.OnboardingHook
      ] do
      live("/onboarding", OnboardingLive)
      live("/subscriptions/new", SubscriptionLive.New)
      live("/subscriptions/done", SubscriptionLive.Done)
      live("/data-targets/:data_target_id/edit", DataTargetLive.New, :edit)
      live("/reports", ReportLive.Index, :index)
      live("/reports/:id/delete", ReportLive.Index, :delete)
      live("/reports/new2", ReportLive.New2, :new)
      live("/reports/:report_id/edit2", ReportLive.New2, :edit)
      live("/reports/:report_id/report_logs", ReportLogLive.Index)
      live("/report_logs", ReportLogLive.Index)
      live("/settings", SettingsLive, :index)
    end

    get "/invoices/:payment_id", InvoiceController, :show

    get "/data-targets/callback/slack", DataTargetController, :slack_callback
    get "/payment/callback/toss-payments", PaymentController, :toss_payments_callback
  end

  scope "/admin", CarrierWeb.Admin, as: :admin do
    pipe_through([:browser, :admin_basic_auth])

    live_session :admin,
      layout: {CarrierWeb.Layouts, :admin},
      on_mount: [] do
      live "/report_logs", ReportLogLive.Index
    end
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
  import Phoenix.LiveDashboard.Router

  scope "/" do
    pipe_through([:browser, :auth_admin])

    live_dashboard("/dashboard", metrics: CarrierWeb.Telemetry)
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through(:browser)

      get "/test", CarrierWeb.TestController, :index

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  if Mix.env() == :prod do
    forward "/", CarrierWeb.FallbackPlug
  end

  defp admin_basic_auth(conn, _opts) do
    auth = Application.get_env(:carrier_web, :basic_auth)
    username = auth[:username]
    password = auth[:password]

    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end
end

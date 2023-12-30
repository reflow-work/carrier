defmodule Carrier.TableauClient do
  use GenServer
  alias Carrier.External.TableauAPI

  @server_name __MODULE__
  @threshold :timer.minutes(10)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def signin(credentials) do
    do_signin(credentials)
  end

  def request(credentials, fun) when is_function(fun, 1) do
    {:ok, auth} = GenServer.call(__MODULE__, {:get_auth, credentials}, :timer.seconds(10))

    case fun.(auth) do
      {:error, {error_code, _}}
      when error_code in [
             :tableau_api_invalid_access_token,
             :tableau_api_invalid_auth_credentials
           ] ->
        :ok = GenServer.call(__MODULE__, {:expire_auth, credentials})

        # retry once
        {:ok, auth} = GenServer.call(__MODULE__, {:get_auth, credentials})
        fun.(auth)

      result ->
        result
    end
  end

  # def put_token(token_key, token, expired_at) do
  #   GenServer.call(__MODULE__, {:put_token, token_key, token, expired_at})
  # end

  @impl true
  def init(_) do
    @server_name =
      :ets.new(@server_name, [:set, :protected, :named_table, read_concurrency: true])

    {:ok, nil}
  end

  @impl true
  def handle_call({:get_auth, credentials}, _from, state) do
    response =
      case get_auth_from_ets(credentials) do
        {:ok, auth} ->
          {:ok, auth}

        :error ->
          {:ok, auth} = do_signin(credentials)

          put_auth_token_to_ets(credentials, auth)

          {:ok, auth}
      end

    {:reply, response, state}
  end

  @impl true
  def handle_call({:expire_auth, credentials}, _from, state) do
    :ets.delete(@server_name, credentials)

    {:reply, :ok, state}
  end

  defp get_auth_from_ets(credentials) do
    with [{^credentials, auth}] <- :ets.lookup(@server_name, credentials),
         false <- expired?(auth) do
      {:ok, auth}
    else
      _ -> :error
    end
  end

  defp put_auth_token_to_ets(credentials, auth) do
    :ets.delete(@server_name, credentials)
    true = :ets.insert(@server_name, {credentials, auth})
  end

  defp expired?(%{expired_at: expired_at}) do
    DateTime.diff(expired_at, DateTime.utc_now(), :millisecond) < @threshold
  end

  defp expired?(_) do
    false
  end

  defp do_signin(%{type: :user, host: host, email: email, password: password, site: site}) do
    TableauAPI.signin(%{type: :user, host: host, name: email, password: password, site: site})
  end

  defp do_signin(%{type: :pat, host: host, pat_name: pat_name, pat_secret: pat_secret, site: site}) do
    TableauAPI.signin(%{
      type: :pat,
      host: host,
      pat_name: pat_name,
      pat_secret: pat_secret,
      site: site
    })
  end
end

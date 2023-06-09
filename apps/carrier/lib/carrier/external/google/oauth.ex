defmodule Carrier.External.Google.OAuth do
  defmodule VerifyHook do
    use Joken.Hooks

    @impl true
    def before_verify(_options, {jwt, %Joken.Signer{} = _signer}) do
      with {:ok, %{"kid" => kid}} <- Joken.peek_header(jwt),
           {:ok, algorithm, key} <- GoogleCerts.fetch(kid) do
        {:cont, {jwt, Joken.Signer.create(algorithm, key)}}
      else
        _error -> {:halt, {:error, :no_signer}}
      end
    end
  end

  defmodule JWTManager do
    use Joken.Config, default_signer: nil
    alias Carrier.External.Google.OAuth

    @iss "https://accounts.google.com"

    # your google client id (usually ends in *.apps.googleusercontent.com)
    defp aud do
      OAuth.client_id()
    end

    # reference your custom verify hook here
    add_hook(OAuth.VerifyHook)

    @impl Joken.Config
    def token_config do
      default_claims(skip: [:aud, :iss])
      |> add_claim("iss", nil, &(&1 == @iss))
      |> add_claim("aud", nil, &(&1 == aud()))
    end
  end

  alias Carrier.Core.Crypto

  def verify_credential(credential) do
    {:ok, %{"email" => email}} = JWTManager.verify_and_validate(credential)

    {:ok, %{email: email}}
  end

  def client_id() do
    Application.get_env(:carrier, :google)[:client_id]
  end
end

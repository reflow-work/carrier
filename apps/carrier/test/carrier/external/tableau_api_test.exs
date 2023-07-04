defmodule Carrier.External.TableauAPITest do
  use ExUnit.Case
  alias Carrier.External.TableauAPI
  alias Carrier.ExternalHelper

  setup do
    bypass = Bypass.open(port: 4102)

    %{bypass: bypass}
  end

  describe "signin/1" do
    @success_resp Carrier.Fixture.json("tableau_api/signin.user.success.json")

    test "with valid params (user)", %{bypass: bypass} do
      params = %{
        type: :user,
        host: "http://localhost:4102",
        site: "reflow",
        name: "tableau@reflow.work",
        password: "password"
      }

      ExternalHelper.expect(
        bypass,
        :post,
        "/api/3.18/auth/signin",
        {:json, @success_resp},
        validate: fn _conn, body ->
          assert body == %{
                   "credentials" => %{
                     "name" => params[:name],
                     "password" => params[:password],
                     "site" => %{"contentUrl" => params[:site]}
                   }
                 }
        end
      )

      assert {:ok, %{token: token, site_id: site_id}} = TableauAPI.signin(params)
      assert token == @success_resp["credentials"]["token"]
      assert site_id == @success_resp["credentials"]["site"]["id"]
    end

    @success_resp Carrier.Fixture.json("tableau_api/signin.pat.success.json")

    test "with valid params (pat)", %{bypass: bypass} do
      params = %{
        type: :pat,
        host: "http://localhost:4102",
        site: "reflow",
        pat_name: "reflow",
        pat_secret: "secret"
      }

      ExternalHelper.expect(
        bypass,
        :post,
        "/api/3.18/auth/signin",
        {:json, @success_resp},
        validate: fn _conn, body ->
          assert body == %{
                   "credentials" => %{
                     "personalAccessTokenName" => params[:pat_name],
                     "personalAccessTokenSecret" => params[:pat_secret],
                     "site" => %{"contentUrl" => params[:site]}
                   }
                 }
        end
      )

      assert {:ok, %{token: token, site_id: site_id}} = TableauAPI.signin(params)
      assert token == @success_resp["credentials"]["token"]
      assert site_id == @success_resp["credentials"]["site"]["id"]
    end

    @fail_resp Carrier.Fixture.json("tableau_api/signin.fail.json")

    test "with invalid params", %{bypass: bypass} do
      params = %{
        type: :user,
        host: "http://localhost:4102",
        site: "reflow",
        name: "invalid",
        password: "invalid"
      }

      ExternalHelper.expect(
        bypass,
        :post,
        "/api/3.18/auth/signin",
        {:json, @fail_resp},
        status: 401
      )

      assert {:error, {:tableau_api_invalid_access_token, "Error signing in to Tableau Server"}} =
               TableauAPI.signin(params)
    end
  end
end

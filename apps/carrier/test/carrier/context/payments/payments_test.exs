defmodule Carrier.PaymentsTest do
  use Carrier.DataCase, async: true
  use Carrier.Payments

  @moduletag repo: Carrier.TenantRepo
  describe "create_credit_card/1" do
    setup do
      org = TenantFactory.insert(:org)
      TenantRepo.put_org_id(org.org_id)

      %{org: org}
    end

    test "with valid params", %{org: org} do
      params = %{
        org_id: org.org_id,
        provider: :toss_payments,
        billing_key: "billing_key",
        customer_key: "customer_key",
        card_company: "현대",
        card_number: "41352680****123*"
      }

      assert {:ok, %CreditCard{} = credit_card} = Payments.create_credit_card(params)

      assert credit_card.org_id == org.org_id
      assert credit_card.provider == :toss_payments
      assert credit_card.billing_key == "billing_key"
      assert credit_card.customer_key == "customer_key"
      assert credit_card.card_company == "현대"
      assert credit_card.card_number == "41352680****123*"
    end

    test "with duplicated org_id", %{org: org} do
      params = %{
        org_id: org.org_id,
        provider: :toss_payments,
        billing_key: "billing_key",
        customer_key: "customer_key",
        card_company: "현대",
        card_number: "41352680****123*"
      }

      {:ok, %CreditCard{}} = Payments.create_credit_card(params)

      assert {:error, %Ecto.Changeset{errors: errors}} = Payments.create_credit_card(params)
      assert [org_id: {"has already been taken", _}] = errors
    end

    test "with duplicated org_id but deleted", %{org: org} do
      params = %{
        org_id: org.org_id,
        provider: :toss_payments,
        billing_key: "billing_key",
        customer_key: "customer_key",
        card_company: "현대",
        card_number: "41352680****123*"
      }

      {:ok, %CreditCard{} = credit_card} = Payments.create_credit_card(params)

      credit_card |> Ecto.Changeset.change(deleted_at: DateTime.utc_now()) |> TenantRepo.update!()

      assert {:ok, %CreditCard{}} = Payments.create_credit_card(params)
    end
  end
end

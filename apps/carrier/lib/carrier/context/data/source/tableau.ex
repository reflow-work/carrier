defmodule Carrier.Data.Source.Tableau do
  @behaviour Carrier.Data.Source

  use Carrier.{Integrations, Reports}
  alias Carrier.Data.Block
  alias Carrier.External.TableauAPI
  alias Carrier.Core.{Async, Tmp}
  alias Carrier.{Uploader, PDF}
  alias Carrier.Fixture

  ### models

  defmodule Pagination do
    defstruct [:page, :page_size, :total]

    def new(%{
          "pageNumber" => page_str,
          "pageSize" => page_size_str,
          "totalAvailable" => total_str
        }) do
      %__MODULE__{
        page: String.to_integer(page_str),
        page_size: String.to_integer(page_size_str),
        total: String.to_integer(total_str)
      }
    end
  end

  # https://help.tableau.com/current/pro/desktop/en-us/embed_structure.htm
  defmodule View do
    defstruct [:id, :name, :workbook_id, :full_name, :view_path]

    def new(%{
          "id" => id,
          "name" => name,
          "location" => %{"type" => "Project"},
          "project" => %{"name" => project_name},
          "workbook" => %{
            "id" => workbook_id,
            "name" => workbook_name,
            "contentUrl" => workbook_content_url
          },
          "viewUrlName" => viewUrlName
        }) do
      %__MODULE__{
        id: id,
        name: name,
        workbook_id: workbook_id,
        full_name: "#{project_name} / #{workbook_name} / #{name}",
        view_path: "#{workbook_content_url}/#{viewUrlName}"
      }
    end

    def new(%{
          "id" => id,
          "name" => name,
          "location" => %{"type" => "PersonalSpace"},
          "workbook" => %{
            "id" => workbook_id,
            "name" => workbook_name,
            "contentUrl" => workbook_content_url
          },
          "viewUrlName" => viewUrlName
        }) do
      %__MODULE__{
        id: id,
        name: name,
        workbook_id: workbook_id,
        full_name: "Personal Space / #{workbook_name} / #{name}",
        view_path: "#{workbook_content_url}/#{viewUrlName}"
      }
    end

    def view_url(%__MODULE__{view_path: view_path}, host, site) do
      "#{host}/#/site/#{site}/views/#{view_path}"
    end
  end

  ### behaviors

  @impl true
  def validate_conn(:tableau, credentials, _opts) do
    case signin(credentials) do
      {:ok, _} -> :ok
      {:error, _} -> {:error, :invalid_conn_info}
    end
  end

  @impl true
  def load_raw_data(
        %{data_source_info: %{params: %{views: views}}},
        %DataSource{source: :tableau} = data_source
      ) do
    with %{host: host, site: site} = credentials = DataSource.to_credentials(data_source),
         {:ok, auth} <- signin(credentials),
         view_ids = views |> Enum.map(& &1.id),
         {:ok, views} <- view_ids |> do_list_views_async(auth),
         {:ok, view_image_binaries} <- view_ids |> do_list_view_image_binaries_async(auth),
         {:ok, view_pdf_binaries} <- view_ids |> do_list_view_pdf_binaries_async(auth) do
      views =
        views
        |> Enum.map(&(&1 |> Map.put(:view_url, View.view_url(&1, host, site))))

      {:ok,
       %{
         views: views,
         view_image_binaries: view_image_binaries,
         view_pdf_binaries: view_pdf_binaries
       }}
    end
  end

  @impl true
  def transform_data(%{org_id: org_id}, %DataSource{source: :tableau}, %{
        views: views,
        view_image_binaries: view_image_binaries,
        view_pdf_binaries: view_pdf_binaries
      }) do
    with {:ok, view_image_urls} <-
           view_image_binaries
           |> Async.map(&Uploader.upload(:report_storage, org_id, &1, :png))
           |> Async.unwrap_map_ok_results(),
         merged_pdf_binary = merge_pdf_binaries(view_pdf_binaries),
         {:ok, pdf_url} <- Uploader.upload(:report_storage, org_id, merged_pdf_binary, :pdf) do
      {:ok, %{views: views, view_image_urls: view_image_urls, pdf_url: pdf_url}}
    end
  end

  @impl true
  def data_to_threads(_params, %DataSource{source: :tableau}, %{
        views: views,
        view_image_urls: view_image_urls,
        pdf_url: pdf_url
      }) do
    threads =
      [views, view_image_urls]
      |> Enum.zip_with(fn [%{full_name: full_name, view_url: view_url}, view_image_url] ->
        [
          Block.link(full_name, view_url),
          Block.image(full_name, view_image_url, full_name),
          Block.button("Open Original Image", view_image_url)
        ]
      end)

    threads = threads ++ [[Block.button("Open PDF", pdf_url)]]

    {:ok, threads}
  end

  ### raw functions

  def signin(%{host: host} = credentials) do
    with {:ok, %{token: token, site_id: site_id}} <- do_signin(credentials) do
      {:ok, %{host: host, token: token, site_id: site_id}}
    end
  end

  def list_views(%DataSource{source: :tableau} = data_source) do
    credentials = data_source |> DataSource.to_credentials()

    with {:ok, auth} <- signin(credentials),
         {:ok, views} <- do_list_views(auth) do
      {:ok, views}
    end
  end

  def list_views(%DataSource{source: :tableau_demo}) do
    %{"views" => %{"view" => raw_views}} =
      Fixture.json("tableau_api/query_views_for_site.success.json")

    views = raw_views |> Enum.map(&View.new(&1))

    {:ok, views}
  end

  def get_view_preview_image_binary(
        workbook_id,
        view_id,
        %DataSource{source: :tableau} = data_source
      ) do
    credentials = data_source |> DataSource.to_credentials()

    with {:ok, auth} <- signin(credentials),
         {:ok, view_preview_image_binary} <-
           do_get_preview_image_binary(workbook_id, view_id, auth) do
      {:ok, view_preview_image_binary}
    end
  end

  def get_view_preview_image_binary(workbook_id, view_id, %DataSource{source: :tableau_demo}) do
    view_preview_image_binary = Fixture.read("tableau_api/view_preview_images/#{view_id}")

    {:ok, view_preview_image_binary}
  end

  def get_view_image_binary(view_id, credentials) do
    with {:ok, auth} <- signin(credentials),
         {:ok, view_image_binary} <- do_get_view_image_binary(view_id, auth) do
      {:ok, view_image_binary}
    end
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

  defp do_list_views(%{host: host, site_id: site_id, token: token}) do
    Stream.unfold(1, fn
      nil ->
        nil

      page ->
        {:ok,
         %{views: views, pagination: %Pagination{page: page, page_size: page_size, total: total}}} =
          TableauAPI.query_views_for_site(%{
            host: host,
            site_id: site_id,
            page: page,
            token: token
          })

        last_page = div(total, page_size) + 1

        case last_page == page do
          true -> {views, nil}
          false -> {views, page + 1}
        end
    end)
    |> Enum.to_list()
    |> List.flatten()
    |> then(&{:ok, &1})
  end

  defp do_list_views_async(view_ids, auth) do
    with {:ok, results} <-
           view_ids
           |> Async.map(fn view_id -> do_get_view(view_id, auth) end)
           |> Async.unwrap_map_ok_results() do
      {:ok, results}
    end
  end

  defp do_list_view_image_binaries_async(view_ids, auth) do
    with {:ok, results} <-
           view_ids
           |> Async.map(fn view_id -> do_get_view_image_binary(view_id, auth) end)
           |> Async.unwrap_map_ok_results() do
      {:ok, results}
    end
  end

  defp do_list_view_pdf_binaries_async(view_ids, auth) do
    with {:ok, results} <-
           view_ids
           |> Async.map(fn view_id -> do_get_view_pdf_binary(view_id, auth) end)
           |> Async.unwrap_map_ok_results() do
      {:ok, results}
    end
  end

  defp do_get_view(view_id, %{host: host, site_id: site_id, token: token}) do
    TableauAPI.get_view(%{host: host, site_id: site_id, view_id: view_id, token: token})
  end

  defp do_get_preview_image_binary(workbook_id, view_id, %{
         host: host,
         site_id: site_id,
         token: token
       }) do
    TableauAPI.query_view_preview_image(%{
      host: host,
      site_id: site_id,
      workbook_id: workbook_id,
      view_id: view_id,
      token: token
    })
  end

  defp do_get_view_image_binary(view_id, %{host: host, site_id: site_id, token: token}) do
    TableauAPI.query_view_image(%{
      host: host,
      site_id: site_id,
      view_id: view_id,
      token: token
    })
  end

  defp do_get_view_pdf_binary(view_id, %{host: host, site_id: site_id, token: token}) do
    TableauAPI.query_view_pdf(%{
      host: host,
      site_id: site_id,
      view_id: view_id,
      token: token
    })
  end

  defp merge_pdf_binaries(pdf_binaries) do
    pdf_file_paths =
      pdf_binaries
      |> Enum.map(fn pdf_binary ->
        file_path = Tmp.tmp_path(".pdf")
        :ok = File.write!(file_path, pdf_binary)
        file_path
      end)

    merged_pdf_file_path = PDF.merge(pdf_file_paths)

    File.read!(merged_pdf_file_path)
  end
end

defmodule Carrier.Data.Source.Tableau do
  @behaviour Carrier.Data.Source

  use Carrier.{Integrations, Reports}
  alias Carrier.Data.Block
  alias Carrier.External.TableauAPI
  alias Carrier.Core.{Async, Tmp}
  alias Carrier.{Uploader, PDF}

  ### behaviors

  @impl true
  def validate_conn(:tableau, credentials, _opts) do
    case signin(credentials) do
      {:ok, _} -> :ok
      {:error, _} -> {:error, :invalid_conn_info}
    end
  end

  @impl true
  def load_raw_data(%DataSource{source: :tableau} = data_source, %{views: views}) do
    with credentials = DataSource.to_credentials(data_source),
         {:ok, auth} <- signin(credentials),
         view_ids = views |> Enum.map(& &1.id),
         {:ok, views} <- view_ids |> do_list_views_async(auth),
         {:ok, view_image_binaries} <- view_ids |> do_list_view_image_binaries_async(auth),
         {:ok, view_pdf_binaries} <- view_ids |> do_list_view_pdf_binaries_async(auth) do
      raw_data =
        [views, view_image_binaries, view_pdf_binaries]
        |> Enum.zip_with(fn [view, view_image_binary, view_pdf_binary] ->
          view |> Map.merge(%{image_binary: view_image_binary, pdf_binary: view_pdf_binary})
        end)

      {:ok, raw_data}
    end
  end

  @impl true
  def transform_data(%DataSource{source: :tableau, org_id: org_id}, views) do
    [views, pdf_binaries] =
      views
      |> Enum.map(fn view ->
        {pdf_binary, view} = view |> Map.pop(:pdf_binary)

        [view, pdf_binary]
      end)
      |> Enum.zip_with(& &1)

    with {:ok, view_image_urls} <-
           views
           |> Async.map(
             fn %{image_binary: image_binary} ->
               Uploader.upload(:report_storage, org_id, image_binary, :png)
             end,
             timeout: :timer.seconds(30)
           )
           |> Async.unwrap_map_ok_results(),
         merged_pdf_binary = merge_pdf_binaries(pdf_binaries),
         {:ok, pdf_url} <- Uploader.upload(:report_storage, org_id, merged_pdf_binary, :pdf) do
      views =
        Enum.zip_with(views, view_image_urls, fn view, view_image_url ->
          view |> Map.put(:image_url, view_image_url)
        end)

      {:ok, %{views: views, pdf_url: pdf_url}}
    end
  end

  @impl true
  def data_to_threads(%DataSource{source: :tableau}, %{views: views, pdf_url: pdf_url}) do
    threads =
      views
      |> Enum.map(fn %{full_name: full_name, image_url: image_url} ->
        [
          Block.text(full_name, :bold),
          Block.image(full_name, image_url, full_name)
        ]
      end)

    threads = threads ++ [[Block.button("Open PDF", pdf_url)]]

    {:ok, threads}
  end

  ### raw functions

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

  defmodule View do
    defstruct [:id, :name, :full_name]

    def new(%{
          "id" => id,
          "name" => name,
          "location" => %{"type" => "Project"},
          "project" => %{"name" => project_name},
          "workbook" => %{"name" => workbook_name}
        }) do
      %__MODULE__{id: id, name: name, full_name: "#{project_name} / #{workbook_name} / #{name}"}
    end

    def new(%{
          "id" => id,
          "name" => name,
          "location" => %{"type" => "PersonalSpace"},
          "workbook" => %{"name" => workbook_name}
        }) do
      %__MODULE__{id: id, name: name, full_name: "Personal Space / #{workbook_name} / #{name}"}
    end
  end

  def signin(%{host: host} = credentials) do
    with {:ok, %{token: token, site_id: site_id}} <- do_signin(credentials) do
      {:ok, %{host: host, token: token, site_id: site_id}}
    end
  end

  def list_views(credentials) do
    with {:ok, auth} <- signin(credentials),
         {:ok, views} <- do_list_views(auth) do
      {:ok, views}
    end
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
           |> Async.map(fn view_id -> do_get_view(view_id, auth) end,
             timeout: :timer.seconds(30)
           )
           |> Async.unwrap_map_ok_results() do
      {:ok, results}
    end
  end

  defp do_list_view_image_binaries_async(view_ids, auth) do
    with {:ok, results} <-
           view_ids
           |> Async.map(fn view_id -> do_get_view_image_binary(view_id, auth) end,
             timeout: :timer.seconds(30)
           )
           |> Async.unwrap_map_ok_results() do
      {:ok, results}
    end
  end

  defp do_list_view_pdf_binaries_async(view_ids, auth) do
    with {:ok, results} <-
           view_ids
           |> Async.map(fn view_id -> do_get_view_pdf_binary(view_id, auth) end,
             timeout: :timer.seconds(30)
           )
           |> Async.unwrap_map_ok_results() do
      {:ok, results}
    end
  end

  defp do_get_view(view_id, %{host: host, site_id: site_id, token: token}) do
    TableauAPI.get_view(%{host: host, site_id: site_id, view_id: view_id, token: token})
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

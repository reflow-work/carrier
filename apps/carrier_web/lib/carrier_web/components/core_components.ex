defmodule CarrierWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At the first glance, this module may seem daunting, but its goal is
  to provide some core building blocks in your application, such modals,
  tables, and forms. The components are mostly markup and well documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  import CarrierWeb.Gettext
  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal.

  # Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :is_show_close_button, :boolean, default: true
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      data-close={JS.exec("phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-5xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-8 shadow-lg ring-1 transition"
            >
              <div :if={@is_show_close_button} class="absolute top-4 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-2 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # @doc """
  # Renders flash notices.

  # ## Examples

  #     <.flash kind={:info} flash={@flash} />
  #     <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  # """
  # attr :id, :string, default: "flash", doc: "the optional id of flash container"
  # attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  # attr :title, :string, default: nil
  # attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  # attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  # slot :inner_block, doc: "the optional inner block that renders the flash message"

  # def flash(assigns) do
  #   ~H"""
  #   <div
  #     :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
  #     id={@id}
  #     phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
  #     role="alert"
  #     class={[
  #       "fixed top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
  #       @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
  #       @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
  #     ]}
  #     {@rest}
  #   >
  #     <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
  #       <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
  #       <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
  #       <%= @title %>
  #     </p>
  #     <p class="mt-2 text-sm leading-5"><%= msg %></p>
  #     <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
  #       <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
  #     </button>
  #   </div>
  #   """
  # end

  # @doc """
  # Shows the flash group with standard titles and content.

  # ## Examples

  #     <.flash_group flash={@flash} />
  # """
  # attr :flash, :map, required: true, doc: "the map of flash messages"

  # def flash_group(assigns) do
  #   ~H"""
  #   <.flash kind={:info} title="Success!" flash={@flash} />
  #   <.flash kind={:error} title="Error!" flash={@flash} />
  #   <.flash
  #     id="disconnected"
  #     kind={:error}
  #     title="We can't find the internet"
  #     phx-disconnected={show("#disconnected")}
  #     phx-connected={hide("#disconnected")}
  #     hidden
  #   >
  #     Attempting to reconnect <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
  #   </.flash>
  #   """
  # end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"
  attr :errors, :any, default: []

  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    assigns =
      assigns
      |> update(:rest, fn rest -> Map.put_new(rest, :autocomplete, "off") end)

    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class={["space-y-5", @class]}>
        <%= render_slot(@inner_block, f) %>
        <.error :for={error <- @errors}><%= inspect(error) %></.error>
        <div :for={action <- @actions} class="!mt-10 flex items-center gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :any, default: nil
  attr :style, :atom, values: ~w(primary outline)a, default: :primary
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg py-3 px-4",
        "text-sm font-semibold leading-6",
        "disabled:cursor-not-allowed disabled:opacity-75",
        @style == :primary &&
          "bg-zinc-900 hover:bg-zinc-700 text-white active:text-white/80 disabled:bg-zinc-700",
        @style == :outline &&
          "bg-white text-zinc-900 border border-zinc-700 hover:bg-zinc-700 hover:text-white disabled:bg-zinc-300 disabled:text-zinc-500 disabled:border-0",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values:
      ~w(checkbox checkgroup color date datetime-local email file hidden month number password
               range radio radio-group search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :label_align, :atom, default: :top, values: ~w(top left)a
  attr :class, :any, default: nil
  attr :input_class, :any, default: nil

  attr :rest, :global,
    include: ~w(autocomplete cols disabled form list max maxlength min minlength
                pattern placeholder readonly required rows size step)

  slot :label_element, doc: "the slot for the label element"
  slot :icon

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> update(:rest, fn rest -> Map.put_new(rest, :autocomplete, "off") end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div class={@class} phx-feedback-for={@name}>
      <label class="flex items-center gap-2 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        <%= if slot_exist?(@label_element) do %>
          <.label for={@id}><%= render_slot(@label_element) %></.label>
        <% else %>
          <.label for={@id}><%= @label %></.label>
        <% end %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # https://fly.io/phoenix-files/making-a-checkboxgroup-input/
  def input(%{type: "checkgroup"} = assigns) do
    assigns =
      assigns
      |> update(
        :options,
        &(&1
          |> Enum.map(fn
            {label, value} -> {label, value}
            value -> {value, value}
          end))
      )

    ~H"""
    <div
      class={[
        @label_align == :top && nil,
        @label_align == :left && "flex items-center gap-2",
        @class
      ]}
      phx-feedback-for={@name}
    >
      <%= if slot_exist?(@label_element) do %>
        <.label for={@id} align={@label_align}><%= render_slot(@label_element) %></.label>
      <% else %>
        <.label for={@id} align={@label_align}><%= @label %></.label>
      <% end %>
      <div class={[
        @label && @label_align == :top && "mt-1 w-full",
        @label && @label_align == :left && "flex-1"
      ]}>
        <input type="hidden" name={@name} value="" />
        <label
          :for={{label, value} <- @options}
          class="flex items-center gap-2 text-sm leading-6 text-zinc-600"
        >
          <input
            type="checkbox"
            id={"#{@name}-#{value}"}
            name={@name}
            value={value}
            checked={value in @value}
            class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
            {@rest}
          />
          <.label for={@id}><%= label %></.label>
        </label>
        <.error :for={msg <- @errors}><%= msg %></.error>
      </div>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    assigns =
      case assigns.prompt do
        prompt when is_binary(prompt) ->
          assigns
          |> update(:options, &[[key: prompt, value: "", disabled: true] | &1])

        nil ->
          assigns
      end

    ~H"""
    <div
      class={[
        @label_align == :top && nil,
        @label_align == :left && "flex items-center gap-2",
        @class
      ]}
      phx-feedback-for={@name}
    >
      <%= if slot_exist?(@label_element) do %>
        <.label for={@id} align={@label_align}><%= render_slot(@label_element) %></.label>
      <% else %>
        <.label for={@id} align={@label_align}><%= @label %></.label>
      <% end %>
      <div class={[
        @label && @label_align == :top && "mt-1 w-full",
        @label && @label_align == :left && "flex-1"
      ]}>
        <select
          id={@id}
          name={@name}
          class={[
            "select w-full block rounded-md border border-gray-300 bg-white shadow-sm",
            "focus:border-zinc-400 focus:ring-0 sm:text-sm !leading-6",
            @input_class
          ]}
          multiple={@multiple}
          {@rest}
        >
          <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
        </select>
        <.error :for={msg <- @errors}><%= msg %></.error>
      </div>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class={@class} phx-feedback-for={@name}>
      <%= if slot_exist?(@label_element) do %>
        <.label for={@id}><%= render_slot(@label_element) %></.label>
      <% else %>
        <.label for={@id}><%= @label %></.label>
      <% end %>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full h-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          "min-h-[6rem] border-zinc-300 focus:border-zinc-400",
          "resize-none",
          "disabled:bg-zinc-50",
          @errors != [] && "border-rose-400 focus:border-rose-400",
          @input_class
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "radio-group"} = assigns) do
    ~H"""
    <div class={@class} phx-feedback-for={@name}>
      <%= if slot_exist?(@label_element) do %>
        <.label><%= render_slot(@label_element) %></.label>
      <% else %>
        <.label><%= @label %></.label>
      <% end %>
      <label :for={{label, value} <- @options} class="label block cursor-pointer">
        <input type="radio" id={@id} name={@name} value={value} checked={@value == value} />
        <span class="label-text"><%= label %></span>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div
      class={[
        @label_align == :top && nil,
        @label_align == :left && "flex items-center gap-2",
        @class
      ]}
      phx-feedback-for={@name}
    >
      <%= if slot_exist?(@label_element) do %>
        <.label for={@id} align={@label_align}><%= render_slot(@label_element) %></.label>
      <% else %>
        <.label for={@id} align={@label_align}><%= @label %></.label>
      <% end %>
      <div class={[
        "relative",
        @label_align == :top && "mt-1 w-full",
        @label_align == :left && "flex-1"
      ]}>
        <div :if={slot_exist?(@icon)} class="absolute right-3 top-2.5">
          <%= render_slot(@icon) %>
        </div>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            "h-12 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
            "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
            "border-zinc-300 focus:border-zinc-400",
            @errors != [] && "border-rose-400 focus:border-rose-400",
            if(slot_exist?(@icon), do: "pr-10"),
            @input_class
          ]}
          {@rest}
        />
        <.error :for={msg <- @errors}><%= msg %></.error>
      </div>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :label, :string, default: nil

  def field_adder(assigns) do
    ~H"""
    <label class="block cursor-pointer">
      <input type="checkbox" name={@name} class="hidden" />
      <.icon name="hero-plus-circle" /><%= @label %>
    </label>
    """
  end

  attr :for, :any, required: true
  attr :name, :string, required: true

  def field_adder_hidden(assigns) do
    ~H"""
    <input type="hidden" name={@name} value={@for.index} />
    """
  end

  attr :for, :any, required: true
  attr :name, :string, required: true
  attr :label, :string, default: nil

  def field_remover(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn %{for: for} -> "#{for.id}-delete" end)

    ~H"""
    <input
      id={@id}
      type="hidden"
      name={@name}
      data-delete={
        JS.set_attribute({"value", @for.index})
        |> JS.dispatch("input")
        |> JS.remove_attribute("value")
      }
    />
    <button type="button" phx-click={JS.exec("data-delete", to: "##{@id}")}>
      <.icon name="hero-x-mark" /><%= @label %>
    </button>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  attr :align, :atom, default: :top, values: [:top, :left]
  attr :class, :any, default: nil

  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label
      for={@for}
      class={[
        "block text-sm font-semibold leading-6 text-zinc-800",
        @align == :left && "w-28",
        @class
      ]}
    >
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :any, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assigns
        |> assign(row_id: assigns.row_id || fn {id, _item} -> id end)
        |> assign(row_item: assigns[:row_item] || fn {_id, item} -> item end)
      end
      |> assign_new(:row_item, fn -> &Function.identity/1 end)

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500 bg-gray-100 text-xs">
          <tr>
            <th :for={col <- @col} class="p-0 pr-6 py-1 font-normal px-2"><%= col[:label] %></th>
            <th :if={slot_exist?(@action)} class="relative px-2 pb-4">
              <span class="sr-only"><%= gettext("Actions") %></span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative bg-white divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0 px-2", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-2 text-xs pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0 px-2">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500"><%= item.title %></dt>
          <dd class="text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global

  def loading(assigns) do
    ~H"""
    <.icon name="hero-arrow-path" class={["mt-4 w-6 h-6 animate-spin", ["wow"], @class]} {@rest} />
    """
  end

  @doc """
  Renders a [Hero Icon](https://heroicons.com).

  Hero icons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid an mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from your `assets/vendor/heroicons` directory and bundled
  within your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} {@rest} />
    """
  end

  # JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  def hide_modal_from_server(socket, modal_id) do
    socket
    |> Phoenix.LiveView.push_event("js-exec", %{to: "##{modal_id}", attr: "data-close"})
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(CarrierWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(CarrierWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  defp slot_exist?(slot), do: slot |> Enum.empty?() |> Kernel.not()
end

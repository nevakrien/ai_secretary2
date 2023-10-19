defmodule AiAssistantWeb.Home.CalendarForm do
  use Phoenix.LiveView
  #alias AiAssistantWeb.Router.Helpers, as: Routes

  @impl true
  def mount(_params, _session, socket) do
    date=DateTime.utc_now() |> DateTime.to_date()
    socket=socket
    |>assign( year: date.year)
    |>assign( month: date.month)
    {:ok, socket}
  end

  @impl true
  def handle_event("go", %{"year" => year, "month" => month}, socket) do
    # Validate the inputs, make sure they are numbers, within the valid range, etc.
    # For now, assuming they are valid:
    {:noreply,
     socket
     |> put_flash(:info, "Redirecting to the selected month...")
     |> push_redirect(to: "/calendar/"<>year<>"/"<>month)}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <form phx-submit="go">
      <div class="form-group">
        <label for="year">Year:</label>
        <input type="number" name="year" id="year" value="<%= @year %>" min="2000" max="9999" required />
      </div>

      <div class="form-group">
        <label for="month">Month:</label>
        <input type="number" name="month" id="month" value="<%= @month %>" min="1" max="12" required />
      </div>
      
      <div class="form-group">
        <input type="submit" value="Go" />
      </div>
    </form>
    """
  end
end

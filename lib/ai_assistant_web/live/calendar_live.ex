defmodule AiAssistantWeb.NeedDateTime do
  #!!! allways include the corect js script with this asset
  defmacro __using__(_opts) do
    quote do
      # Import dependencies
      import Phoenix.LiveView
      import Phoenix.HTML
      import Timex # Import Timex for date/time operations

      # Common functionality for handling events
      def handle_event("receive_time", %{"current_time" => time}, socket) do
        IO.puts('recived')
        parsed_time = 
          case Timex.parse(time, "{ISO:Extended}") do
            {:ok, datetime} -> datetime#Timex.format!(datetime, "{RFC1123}")
            {:error, _} -> "Invalid time format received"
          end

        # Call the overridable function
        
        socket=assign(socket, current_time: parsed_time)
        #IO.inspect(parsed_time, label: 'client retrieved time')#when this goes away things work fine???? data race with the mount???
        {:noreply, handle_user_time(socket)}
      end

      # deafault overwrite this
      #def get_events_list(socket), do: socket
    end
  end
end

defmodule AiAssistantWeb.CalendarLive do
  def formatted_time(datetime) when is_binary(datetime), do: datetime

  def formatted_time(%DateTime{} = datetime) do
    "#{datetime.year}-#{datetime.month}-#{datetime.day} #{datetime.hour}:#{datetime.minute}"
  end

  def formatted_time(_), do: "Unexpected input"

  def handle_user_time(socket), do: socket

  def date_to_midnight_datetime(date) do
  # Create a NaiveDateTime at midnight on the given date
  naive_datetime = NaiveDateTime.new!(date.year, date.month, date.day, 0, 0, 0, 0)
  
  # Convert the NaiveDateTime to DateTime with the local time zone
  {:ok, datetime} = DateTime.from_naive(naive_datetime, "Etc/UTC")
  
  datetime
end

end

defmodule AiAssistantWeb.CalendarLive.Index do
  import AiAssistantWeb.CalendarLive
  use Phoenix.LiveView
  use AiAssistantWeb.NeedDateTime
  alias AiAssistant.NoteSpace.Event
  
  @impl true
  def mount(_params, session, socket) do
    # Initialize with an empty form, the current user's ID, and the socket ID for 'myself'
    socket = 
      socket
      #|> assign_new(:event_form, %{})
      |> assign(:current_user_id, session["current_user_id"])
      |> update_events_list()
      |> assign_new(:current_time, fn -> "Not received yet" end)
      |> assign_new(:events, fn -> %{} end)

    {:ok, socket}
  end


  @impl true
  def render(assigns) do
    ~H"""
    <div id="calendar" phx-hook="SendTime">
      <div class='curent-time'>
        <strong>Current time:</strong> <%= formatted_time(@current_time) %>
      </div>
      <div class='add-form'>
        <%= render_event_form(assigns) %>
      </div>
      <!-- Render the list of events here -->
      <div>
        <h2 class='events-headlines'>Events:</h2>
        <%= render_events(assigns)%>
      </div>
    </div>
    """
  end

  defp render_events(assigns) do
    ~H"""
      <ul>
        <%= for {event, index} <- Enum.with_index(@events) do %>
          <li class={if rem(index, 2) == 0, do: "event-item-even", else: "event-item-odd"}>
            <strong>Date:</strong> <%= event.date |> formatted_time %><br>
            <strong>Description:</strong> <%= event.description %>
            <div>
              <button phx-click="delete_event" phx-value-id={event.id}>🗑️</button>
            </div>
          </li>

        <% end %>
      </ul>
    """
  end
  defp render_event_form(assigns) do
    ~L"""
    <div class="centered-form">
      <h2>Add New Event</h2>
      <form phx-submit="save_event">
        <div class="form-group">
          <label for="event_description">Event Description:</label>
          <input type="text" name="event[description]" id="event_description"/>
        </div>
        
        <div class="form-group">
          <label for="event_date">Event Date:</label>
          <input type="date" name="event[date]" id="event_date"/>
        </div>
        
        <div class="form-group">
          <label for="event_time">Event Time:</label>
          <input type="time" name="event[time]" id="event_time" step="60">
        </div>
        
        <div class="form-group" style="text-color var(--color-phx)">
          <input type="submit" value="Add Event" />
        </div>
      </form>
    </div>
    """
  end

  def update_events_list(socket) do
    socket=assign(socket,:events,Event.get_events(socket.assigns.current_user_id,10))
    IO.inspect(socket,label: "socket with events")
  end
  
  @impl true
  def handle_event("save_event", %{"event" => event_params}, socket) do
    IO.puts('save event triggered')
    current_user_id = socket.assigns.current_user_id

    # Extracting date and time from the event_params
    date = Map.fetch!(event_params, "date")
    time = Map.get(event_params, "time") || "00:00" # default to midnight if time is not provided

    # Constructing a string that represents the date and time
    datetime_string = date <> "T" <> time <> ":00" # appending seconds, if your time input doesn't include them

    # Parsing the string into a NaiveDateTime struct.
    naive_datetime = NaiveDateTime.from_iso8601!(datetime_string)
    
    # Convert the naive datetime to UTC datetime
    utc_datetime = DateTime.from_naive!(naive_datetime, "Etc/UTC")

    # Add the datetime and user_id to the event_params
    attrs =  %{"date" => utc_datetime, "user_id" => current_user_id, "description"=>Map.fetch!(event_params, "description")}

    IO.inspect(attrs, label: 'event')

    case Event.create_event(attrs) do
      {:ok, event} ->
        # If the event is saved successfully, you might want to clear the form or emit a success message.
        {:noreply, assign(socket,:events,[event | socket.assigns.events] )}
      {:error, changeset} ->
        # If there's an error, you'll need to handle it here, possibly sending back validation errors to the form.
        IO.inspect(changeset)
        {:noreply, socket}
    end
  end

  # gpt
  def handle_event("delete_event", %{"id" => id}, socket) do
    # Convert the id to integer if it's a string, as database IDs are typically integers.
    id = String.to_integer(id)

    # Assuming you have a delete function in your context
    case Event.delete_event(id) do
      {:ok, _deleted_event} ->
        # If the event was successfully deleted, fetch the updated list of events.
        # You don't necessarily need the deleted event struct, hence the `_deleted_event` variable.
        {:noreply, update_events_list(socket)}
        
      {:error, reason} ->
        # Handle the error case. You might want to log the error or notify the user.
        # For now, we'll just print it to the console.
        IO.inspect(reason, label: "Failed to delete event")
        
        # Do not alter the socket, just send a no-reply response.
        {:noreply, socket}
    end
  end
end

defmodule AiAssistantWeb.CalendarLive.Month do
  import AiAssistantWeb.CalendarLive
  use Phoenix.LiveView
  use AiAssistantWeb.NeedDateTime
  alias AiAssistant.NoteSpace.Event

  @impl true
  def mount(_params, session, socket) do

    IO.inspect(session["year"],label: 'year')
    IO.inspect(session["month"],label: 'month')
    # Initialize with an empty form, the current user's ID, and the socket ID for 'myself'
    socket = 
      socket
      #|> assign_new(:event_form, %{})
      |>assign(:year,String.to_integer(session["year"]))
      |>assign(:month,String.to_integer(session["month"]))
      |> assign(:current_user_id, session["current_user_id"])
    
    socket =
      socket
      |> assign(:days, get_events_list(socket))
      |> assign_new(:current_time, fn -> nil end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="calendar">
      <%= for day_index <- 0..6 do %>
        <div class="week-column">
          <div class="day-header"><%= day_name_from_date(Enum.at(days_for_column(@days, day_index), 0)) %></div>
          <%= for day <- days_for_column(@days, day_index) do %>
            <%= day_render(day) %>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp days_for_column(days, start_index) do
    days
    |> Enum.drop(start_index)
    |> Enum.take_every(7)
  end


  defp day_name_from_date({date, _}) do
    day_name(Date.day_of_week(date))
  end


  defp day_render({date, events}) do
    day_class = if Date.day_of_week(date,:sunday) |> rem(2) == 0, do: "even-day", else: "odd-day"
    event_class = if length(events) > 0, do: "event-day", else: ""

     assigns = %{
      day_class: day_class,
      event_class: event_class,
      date: date,
      events: events,
    }
    
    ~H"""
    <div class={"day " <> @day_class<>" "<> @event_class} id={"day" <> Date.to_string(@date)}> 
      <div class="date"><%= @date %></div>
      <div class="event-count">
        <%= if length(@events) > 0 do %>
          <%= length(@events) %> events
        <%else%> 
          -
        <% end %>
      </div>
    </div>
    """
  end

  def get_events_list(%{assigns: %{current_user_id: id,year: year, month: month}}=_socket) do
    
    # Calculate the first and last days of the month
    first_date_of_calendar = Date.new!(year, month, 1)
    last_date_of_calendar  = Date.add(first_date_of_calendar,Date.days_in_month(first_date_of_calendar) - 1)

    # Find the start of the first week (potentially in the previous month)
    first_date_of_calendar = first_date_of_calendar |> Date.beginning_of_week(:sunday) # assuming weeks start on Sunday
    last_date_of_calendar = last_date_of_calendar |> Date.end_of_week(:sunday) # assuming weeks end on Saturday

    for date <-Date.range(first_date_of_calendar, last_date_of_calendar) do
      {date ,Event.get_events(id,date_to_midnight_datetime(date),3)}
    end
    |> IO.inspect(label: "months events")
  end
end
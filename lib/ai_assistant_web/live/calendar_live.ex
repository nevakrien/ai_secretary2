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

  def date_to_first_in_day_datetime(date) do
    # Create a NaiveDateTime at midnight on the given date
    naive_datetime = NaiveDateTime.new!(date.year, date.month, date.day, 0, 0, 0, 0)
    
    # Convert the NaiveDateTime to DateTime with the local time zone
    {:ok, datetime} = DateTime.from_naive(naive_datetime, "Etc/UTC")
    
    datetime
  end

  def date_to_last_in_day_datetime(date) do
    # Create a NaiveDateTime at 23:59:59 on the given date, representing the end of the day.
    naive_datetime_end_of_day = NaiveDateTime.new!(date, Time.new!(23, 59, 59)) # 23:59:59
    
    # Convert the NaiveDateTime to DateTime with the appropriate time zone, "Etc/UTC" in this case.
    # You should replace "Etc/UTC" with the time zone relevant to your application if different.
    {:ok, datetime} = DateTime.from_naive(naive_datetime_end_of_day, "Etc/UTC")
    
    datetime
  end

  def url_from_date(date) do 
    "/calendar/" <> Integer.to_string(date.year) <>
    "/" <> Integer.to_string(date.month) <>
    "/" <> Integer.to_string(date.day)
  end

  # def url_from_year_and_month(year,month) do 
  #   "calendar/" <> Integer.to_string(year) <>
  #   "/" <> Integer.to_string(month) 
  # end

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
      #|> assign_new(:events, fn -> %{} end)

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

  def render_events(assigns) do
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

  @max_limit 10_000  # Define a module attribute for the maximum limit.
  
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
            <a href= {day_link(day)}>
              <%= day_render(day) %>
            </a>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp day_link({date,_}) do
    #for some reason it keeps the year locked in but not the month no idea why that is
    #to_string(date.month)<>"/"<>to_string(date.day)
    url_from_date(date)
  end

  defp days_for_column(days, start_index) do
    days
    |> Enum.drop(start_index)
    |> Enum.take_every(7)
  end

  defp day_name_from_date({date, _}) do
    date
    |> Date.day_of_week()
    |> day_name()
    |> String.slice(0, 3) 
  end


  defp day_render({date, events}) do
    day_class = if Date.day_of_week(date,:sunday) |> rem(2) == 0, do: "even-day", else: "odd-day"
    event_class = if length(events) > 0, do: "event-day", else: "empty-day"

     assigns = %{
      day_class: day_class,
      event_class: event_class,
      date: date,
      events: events,
    }
    
    ~H"""
    <div class={"day " <> @day_class<>" "<> @event_class} id={"day" <> Date.to_string(@date)}> 
      <div class="date"><%= @date.day %></div>

      <% last_updated_event = Enum.sort_by(@events, & &1.updated_at, {:desc, NaiveDateTime}) |> List.last() %>
      <div class="event-name">
          <%= if last_updated_event do %>
            <%= last_updated_event.description %>
          <%else%> 
              empty
          <% end %>
      </div>
      <div class="event-count">
          <%= if length(@events) > 0 do %>
              events:<%= length(@events) %>
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

    get_events_from_dates(id,first_date_of_calendar,last_date_of_calendar)
    |> IO.inspect(label: "months events")
  end

 

  def get_events_from_dates(user_id, start, finish) do
    start_datetime = date_to_first_in_day_datetime(start)
    end_datetime =date_to_last_in_day_datetime(finish)
                  
    # Fetch events with a high limit to prevent fetching an excessive number of records.
    events = Event.get_events(user_id, start_datetime, end_datetime, @max_limit)

    # Group events by date.
    events = events
    |> Enum.group_by(& &1.date |> DateTime.to_date())

    date_range = Date.range(start, finish)

    # Ensure there's an entry for every date in the range, even if no events are found for that date.
    date_range
    |> Enum.map(fn date -> 
         {date, Map.get(events, date, [])} 
       end)
  end

end



defmodule AiAssistantWeb.CalendarLive.Day do
  import AiAssistantWeb.CalendarLive
  use Phoenix.LiveView
  use AiAssistantWeb.NeedDateTime
  alias AiAssistant.NoteSpace.Event

  alias AiAssistantWeb.CalendarLive.Index 
  #import AiAssistantWeb.CalendarLive.Index, only: [handle_event: 3]


  @impl true
  def mount(_params, session, socket) do
    id=session["current_user_id"]
    {:ok, date}=Date.new(
      String.to_integer(session["year"]),
      String.to_integer(session["month"]),
      String.to_integer(session["day"]))
    
    socket=socket
    |> assign(:date,date)
    |> assign(:year,date.year)
    |> assign(:month,date.month)
    |> assign(:day,date.day)
    |> assign(:current_user_id, id)
    |> update_events_list()
    {:ok,socket}
  end 

  def update_events_list(socket) do
    a=socket.assigns
    assign(socket,:events,Event.get_events(a.current_user_id,date_to_first_in_day_datetime(a.date),1000))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="calendar" phx-hook="SendTime">
      <div class='add-form'>
        <%= render_event_form(assigns) %>
      </div>
      <!-- Render the list of events here -->
      <div>
        <h2 class='events-headlines'>Events:</h2>
        <%= Index.render_events(assigns)%>
      </div>
    </div>
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
  
  @impl true
  def handle_event("save_event", %{"event" => event_params}, socket) do
    IO.puts('save event triggered')
    current_user_id = socket.assigns.current_user_id

    # Extracting date and time from the event_params
    time = Map.get(event_params, "time") || "00:00" # default to midnight if time is not provided
    time=Time.from_iso8601!(time <> ":00")

    # Parsing the string into a NaiveDateTime struct.
    naive_datetime = NaiveDateTime.new!(socket.assigns.date,time)
    
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
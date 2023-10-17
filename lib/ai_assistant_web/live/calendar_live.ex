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
        #IO.puts('recived')
        parsed_time = 
          case Timex.parse(time, "{ISO:Extended}") do
            {:ok, datetime} -> datetime#Timex.format!(datetime, "{RFC1123}")
            {:error, _} -> "Invalid time format received"
          end

        # Call the overridable function
        
        socket=assign(socket, current_time: parsed_time)
        #IO.inspect(parsed_time, label: 'client retrieved time')#when this goes away things work fine???? data race with the mount???
        {:noreply, handle_parsed_time(socket)}
      end

      # deafault overwrite this
      #def handle_parsed_time(socket), do: socket
    end
  end
end

defmodule AiAssistantWeb.CalendarLive.Index do
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
      |> assign_new(:current_time, fn -> "Not received yet" end)
      |> assign_new(:events, fn -> %{} end)

    {:ok, socket}
  end


  @impl true
  def render(assigns) do
    ~H"""
    <div id="calendar" phx-hook="SendTime">
      <div class='curent-time'>
        Current time: <%= formatted_time(@current_time) %>
      </div>
      <div class='add-form'>
        <h2>Add New Event</h2>
        <form phx-submit="save_event">
          <label for="event_description">Event Description:</label>
          <input type="text" name="event[description]" id="event_description"/>
          
          <label for="event_date">Event Date:</label>
          <input type="date" name="event[date]" id="event_date"/>
          <input type="time" name="event[time]" id="event_time" step="1">

          <input type="submit" value="Add Event" />
        </form>
      </div>
      <!-- Render the list of events here -->
      <div>
        <h2 class='events-headlines'>Events:</h2>
        <ul>
          <%= for {event, index} <- Enum.with_index(@events) do %>
            <li class={if rem(index, 2) == 0, do: "event-item-even", else: "event-item-odd"}>
              <strong>Date:</strong> <%= event.date |> formatted_time %><br>
              <strong>Description:</strong> <%= event.description %>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end


  def handle_parsed_time(socket) do
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
    datetime_string = date <> "T" <> time #<> ":00" # appending seconds, if your time input doesn't include them

    # Parsing the string into a NaiveDateTime struct.
    naive_datetime = NaiveDateTime.from_iso8601!(datetime_string)
    
    # Convert the naive datetime to UTC datetime
    utc_datetime = DateTime.from_naive!(naive_datetime, "Etc/UTC")

    # Add the datetime and user_id to the event_params
    attrs =  %{"date" => utc_datetime, "user_id" => current_user_id, "description"=>Map.fetch!(event_params, "description")}

    IO.inspect(attrs, label: 'event')

    case Event.create_event(attrs) do
      {:ok, _event} ->
        # If the event is saved successfully, you might want to clear the form or emit a success message.
        {:noreply, socket}
      {:error, changeset} ->
        # If there's an error, you'll need to handle it here, possibly sending back validation errors to the form.
        IO.inspect(changeset)
        {:noreply, socket}
    end
  end



  def formatted_time(datetime) when is_binary(datetime), do: datetime

  def formatted_time(%DateTime{} = datetime) do
    "#{datetime.year}-#{datetime.month}-#{datetime.day} #{datetime.hour}:#{datetime.minute}"
  end

  def formatted_time(_), do: "Unexpected input"


  #defp formatted_time(time) when is_binary(time), do: time
  #defp formatted_time("Not received yet"), do: "Not received yet"
end


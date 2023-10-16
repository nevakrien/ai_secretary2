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
        parsed_time = 
          case Timex.parse(time, "{ISO:Extended}") do
            {:ok, datetime} -> Timex.format!(datetime, "{RFC1123}")
            {:error, _} -> "Invalid time format received"
          end

        {:noreply, assign(socket, current_time: parsed_time)}
      end

      # You can add more common functions or event handlers here
    end
  end
end

defmodule AiAssistantWeb.CalendarLive do
  use Phoenix.LiveView
  use AiAssistantWeb.NeedDateTime
  alias AiAssistant.NoteSpace.Event
  
  @impl true
  def mount(_params, session, socket) do
    # Initialize with an empty form, the current user's ID, and the socket ID for 'myself'
    socket = 
      socket
      |> assign(:event_form, %{})
      |> assign(:current_user_id, session["current_user_id"])
      |> assign(:current_time, "Not received yet")
      #|> assign(:myself, socket.id) 

    {:ok, socket}
  end


  @impl true
  def render(assigns) do
    ~H"""
    <div id="calendar" phx-hook="SendTime">
      <div>
        Current time: <%= formatted_time(@current_time) %>
      </div>
      <div>
        <h2>Add New Event</h2>
        <form phx-submit="save_event">
          <label for="event_description">Event Description:</label>
          <input type="text" name="event[description]" id="event_description"/>
          
          <label for="event_date">Event Date:</label>
          <input type="date" name="event[date]" id="event_date"/>

          <input type="submit" value="Add Event" />
        </form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("save_event", %{"event" => event_params}, socket) do
    current_user_id = socket.assigns.current_user_id

    # You might need to parse the date if it's submitted as a string, 
    # or ensure it's in the correct format for the changeset function.
    attrs = Map.put(event_params, "user_id", current_user_id)

    case Event.create_event(attrs) do
      {:ok, _event} ->
        # If the event is saved successfully, you might want to clear the form or emit a success message.
        {:noreply, socket |> put_flash(:info, "Event created successfully.")}

      {:error, _changeset} ->
        # If there's an error, you'll need to handle it here, possibly sending back validation errors to the form.
        {:noreply, socket |> put_flash(:error, "Failed to create event.")}
    end
  end



  def formatted_time(time) do
    case time do
      %DateTime{} ->
        time
        |> DateTime.to_naive() # Convert to NaiveDateTime, dropping timezone info
        |> NaiveDateTime.to_string() # Convert to string

      %NaiveDateTime{} ->
        NaiveDateTime.to_string(time) # Already a NaiveDateTime, just convert to string

      _ ->
        "Invalid time format" # or handle this case as per your requirement
      end
  end

  #defp formatted_time(time) when is_binary(time), do: time
  #defp formatted_time("Not received yet"), do: "Not received yet"
end


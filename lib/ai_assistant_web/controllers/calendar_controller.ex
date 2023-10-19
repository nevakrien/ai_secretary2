defmodule AiAssistantWeb.CalendarController do
  use AiAssistantWeb, :controller
  #alias AiAssistantWeb.Router.Helpers, as: Routes

  #alias AiAssistant.Calendar # or whatever the alias is for your context that fetches events

  def calendar_index(conn, _params) do
    # Here you will fetch the events needed for the current month or whatever your logic is
    # events = Calendar.list_events_for_month(...)
    render(conn, :index)#, layout: false)
  end

  def show_month(conn, %{"year" => year, "month" => month}) do
    # You will fetch the events for the specified month
    # events = Calendar.list_events_for_month(year, month)
    IO.puts("went through month")
    render(conn, :month, year: year, month: month) # , events: events
  end

  def show_day(conn, %{"year" => year, "month" => month, "day" => day}) do
    # You will fetch the events for the specified day
    # events = Calendar.list_events_for_day(year, month, day)
    IO.inspect(day,label: 'url day?')
    # Assign the variables to the session not sure why I need it but here
    conn = overite_date(conn, year, month, day)
    render(conn, :day, year: year, month: month, day: day) # , events: events
  end

  defp overite_date(conn, year, month, day) do
  conn
  |> Plug.Conn.put_session(:year, year)
  |> Plug.Conn.put_session(:month, month)
  |> Plug.Conn.put_session(:day, day)
end
end

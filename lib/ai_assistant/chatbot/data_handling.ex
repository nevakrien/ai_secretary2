defmodule AiAssistant.Chatbot.DataHandling do
  alias AiAssistant.NoteSpace.Task
  alias AiAssistant.NoteSpace.Event
  alias AiAssistant.UserTime
  alias AiAssistant.Repo

  import Ecto.Query

  def fetch_task_details(user_id) do
    #tasks
    oldest_uncompleted = fetch_oldest_uncompleted_tasks(user_id, 3)
    newest_completed = fetch_newest_completed_tasks(user_id, 3) 
    recents = fetch_recently_modified_or_added_tasks(user_id, 5) 

    #events
    current_time =UserTime.get_user_local_time(user_id)
    
    upcoming_events =
      if is_nil(current_time) do
        # If current_time is nil, we return an empty list
        []
      else
        fetch_upcoming_events(user_id,current_time,60*12,3) # Assuming fetch_upcoming_events takes 3 arguments
      end
    
    %{
      oldest_uncompleted: oldest_uncompleted,
      newest_completed: newest_completed,
      recently_extras: recents-- oldest_uncompleted -- newest_completed,

      upcoming_events: upcoming_events,
      current_time: current_time,
    }
  end

  #tasks
  defp fetch_oldest_uncompleted_tasks(user_id, n) do
    from(t in Task,
      where: t.user_id == ^user_id and t.completed == false,
      order_by: :inserted_at,
      limit: ^n
    )
    |> Repo.all()
  end


  defp fetch_newest_completed_tasks(user_id, n) do
    from(t in Task,
      where: t.user_id == ^user_id and t.completed == true,
      order_by: [desc: :inserted_at],
      limit: ^n
    )
    |> Repo.all()
  end


  defp fetch_recently_modified_or_added_tasks(user_id, n) do
    from(t in Task,
      where: t.user_id == ^user_id,
      order_by: [desc: fragment("GREATEST(?, ?)", t.inserted_at, t.updated_at)],
      limit: ^n
    )
    |> Repo.all()
  end

  #events
  defp fetch_recently_modified_or_added_events(user_id,n) do 
    from(t in Event,
      where: t.user_id == ^user_id,
      order_by: [desc: fragment("GREATEST(?, ?)", t.inserted_at, t.updated_at)],
      limit: ^n
    )
    |> Repo.all()
  end

  def fetch_upcoming_events(user_id, current_time, future_window_minutes,n) do
    future_cutoff = Timex.shift(current_time, minutes: future_window_minutes)

    from(e in Event,
      where: e.user_id == ^user_id and
             e.date >= ^current_time and
             e.date <= ^future_cutoff,
      order_by: [asc: e.date],
      limit: ^n
    )
    |> Repo.all()
  end

  def fetch_recent_past_events(user_id, current_time, past_window_minutes,n) do
    past_cutoff = Timex.shift(current_time, minutes: -past_window_minutes)

    from(e in Event,
      where: e.user_id == ^user_id and
             e.date < ^current_time and
             e.date >= ^past_cutoff,
      order_by: [desc: e.date],
      limit: ^n
    )
    |> Repo.all()
  end


end
  
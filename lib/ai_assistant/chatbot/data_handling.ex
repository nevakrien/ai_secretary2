defmodule AiAssistant.Chatbot.DataHandling do
  alias AiAssistant.NoteSpace
  alias AiAssistant.NoteSpace.Event
  alias AiAssistant.UserTime
  alias AiAssistant.Repo

  import Ecto.Query

  def fetch_details(user_id) do
    # Start all tasks that are not dependent on current_time for concurrent execution
    task_fetch_oldest = Task.async(fn -> fetch_oldest_uncompleted_tasks(user_id, 3) end)
    task_fetch_newest = Task.async(fn -> fetch_newest_completed_tasks(user_id, 3) end)
    task_fetch_recents = Task.async(fn -> fetch_recently_modified_or_added_tasks(user_id, 5) end)

    current_time = UserTime.get_user_local_time(user_id)
    if is_nil(current_time), do: raise "no time data on this user"

    task_fetch_upcoming = Task.async(fn -> fetch_upcoming_events(user_id, current_time, 60 * 12, 3) end)
    task_fetch_past = Task.async(fn -> fetch_recent_past_events(user_id, current_time, 60 * 12, 3) end)

    # Now, gather all task results
    oldest_uncompleted_tasks = Task.await(task_fetch_oldest)
    newest_completed_tasks = Task.await(task_fetch_newest)
    recents = Task.await(task_fetch_recents)
    upcoming_events = Task.await(task_fetch_upcoming)
    recent_past_events = Task.await(task_fetch_past)

    # Construct the result map
    %{
      oldest_uncompleted_tasks: oldest_uncompleted_tasks,
      newest_completed_tasks: newest_completed_tasks,
      recently_extras_tasks: recents -- oldest_uncompleted_tasks -- newest_completed_tasks,
      upcoming_events: upcoming_events,
      recent_past_events: recent_past_events,
      current_time: current_time
    }
  end

  #tasks
  defp fetch_oldest_uncompleted_tasks(user_id, n) do
    from(t in NoteSpace.Task,
      where: t.user_id == ^user_id and t.completed == false,
      order_by: :inserted_at,
      limit: ^n
    )
    |> Repo.all()
  end


  defp fetch_newest_completed_tasks(user_id, n) do
    from(t in NoteSpace.Task,
      where: t.user_id == ^user_id and t.completed == true,
      order_by: [desc: :inserted_at],
      limit: ^n
    )
    |> Repo.all()
  end


  defp fetch_recently_modified_or_added_tasks(user_id, n) do
    from(t in NoteSpace.Task,
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
  
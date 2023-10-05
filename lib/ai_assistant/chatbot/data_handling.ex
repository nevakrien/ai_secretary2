defmodule AiAssistant.Chatbot.DataHandling do
  alias AiAssistant.NoteSpace.Task
  alias AiAssistant.Repo

  import Ecto.Query

  def fetch_task_details(user_id) do
    oldest_uncompleted = fetch_oldest_uncompleted_tasks(user_id, 3)
    newest_completed = fetch_newest_completed_tasks(user_id, 3) 
    recents = fetch_recently_modified_or_added_tasks(user_id, 5) 
    
    %{
      oldest_uncompleted: oldest_uncompleted,
      newest_completed: newest_completed,
      recently_extras: recents-- oldest_uncompleted -- newest_completed
    }
  end


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
end
  
defmodule AiAssistantWeb.TaskBoardLive do
  use Phoenix.LiveView

  alias AiAssistant.NoteSpace.Task

  # Add this import if it's not already in your module
  import Ecto.Query, only: [from: 2]
  
  @impl true
  def render(assigns) do
    ~H"""
    <form phx-submit="add_task">
      <input type="text" name="text" placeholder="Add a new task..." />
      <button type="submit">Add</button>
    </form>

    <ul style="overflow-y: auto; max-height: 30vh;">
      <%= for task <- @tasks do %>
        <li phx-value-task_id={task.id}>
          <!-- Toggle button with icon based on completion status -->
          <button phx-click="toggle_task_completion" phx-value-task_id={task.id}>
            <%= if task.completed, do: "✔️", else: "□" %>
          </button>

          <input type="text" value={task.text} class="editable-input" phx-blur="update_task_text"
            phx-value-task_id={task.id} style={task.completed and "text-decoration: line-through;"} />
          <button phx-click="delete_task" phx-value-task_id={task.id}>🗑️</button>
        </li>
      <% end %>
    </ul>
    """
  end



  defp fetch_tasks_for_user(user_id) do
    AiAssistant.Repo.all(from t in Task, where: t.user_id == ^user_id, order_by: [desc: t.inserted_at])
  end

  @impl true
  def mount(_params, session, socket) do
    user_id = session["current_user_id"]
    tasks = fetch_tasks_for_user(user_id)

    {:ok, assign(socket, tasks: tasks, new_task_text: "", current_user_id: user_id)}
  end


  # Adding a new task
  @impl true
  def handle_event("add_task", %{"text" => text}, socket) when text != "" do
    attrs = %{
      text: text,
      user_id: socket.assigns.current_user_id,
      completed: false # default value, assuming tasks start as uncompleted
    }

    changeset = Task.changeset(%Task{}, attrs)

    case AiAssistant.Repo.insert(changeset) do
      {:ok, task} ->
        {:noreply, assign(socket, tasks: fetch_tasks_for_user(socket.assigns.current_user_id))}
      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  # Toggle task completion
  @impl true
  def handle_event("toggle_task_completion", %{"task_id" => id}, socket) do
    task = AiAssistant.Repo.get!(Task, id)
    
    attrs = %{
      text: task.text, 
      user_id: task.user_id,
      completed: not task.completed
    }
    
    changeset = Task.changeset(task, attrs)

    case AiAssistant.Repo.update(changeset) do
      {:ok, _updated_task} ->
       {:noreply, assign(socket, tasks: fetch_tasks_for_user(socket.assigns.current_user_id))}
      {:error, _changeset} ->
        {:noreply, socket}
    end
  end


  # Deleting a task
  @impl true
  def handle_event("delete_task", %{"task_id" => id}, socket) do
    task = AiAssistant.Repo.get!(Task, id)
    AiAssistant.Repo.delete(task)

    {:noreply, assign(socket, tasks: fetch_tasks_for_user(socket.assigns.current_user_id))}
  end

  # Updating a task's text
  @impl true
  def handle_event("update_task_text", %{"task_id" => id, "value" => new_text}, socket) when new_text != "" do
    task = AiAssistant.Repo.get!(Task, id)
      
    attrs = %{
      text: new_text, 
      user_id: task.user_id,
      completed: task.completed
    }
      
    changeset = Task.changeset(task, attrs)

    case AiAssistant.Repo.update(changeset) do
      {:ok, _updated_task} ->
        {:noreply, assign(socket, tasks: fetch_tasks_for_user(socket.assigns.current_user_id))}
      {:error, _changeset} ->
        {:noreply, socket}
    end
  end
end

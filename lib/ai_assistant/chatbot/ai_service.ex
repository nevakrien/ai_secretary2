defmodule AiAssistant.Chatbot.AiService do
	@model "gpt-3.5-turbo"

	# defp default_system_prompt do
	#     """
	#     You are a chatbot that only answers questions about the programming language Elixir.
	#     Answer short with just a 1-3 sentences.
	#     If the question is about another programming language, make a joke about it.
	#     If the question is about something else, answer something like:
	#     "I dont know, its not my cup of tea" or "I have no opinion about that topic".
	#     """
	# end  

	def generate_prompt(task_details) do
	  """
	  You are a time management assistant tasked with helping the user with their organization and task completion. Strive to be autonomous, emotionally intelligent, and professional.

	  Before you read the conversation, here are some tasks from the user's task board:

	  #{format_tasks("Old Uncompleted Tasks:", task_details.oldest_uncompleted)}
	  Consider reminding the user about these.

	  #{format_tasks("Recently Completed Tasks:", task_details.newest_completed)}
	  Congratulating the user on a job well done can boost spirits.

	  #{format_tasks("The User Recently Changed/Added These:", task_details.recently_extras)}
	  The user may be referring to these, or they may be on their mind.

	  What follows are your recent messages with the user:
	  """
	end



	 def format_tasks(title, tasks) do
    formatted_tasks = 
      tasks 
      |> Enum.map(&format_task/1)
      |> Enum.join("\n")

    "#{title}\n#{formatted_tasks}\n\n"
  end

  defp format_task(%{text: text, completed: completed}) do
    status_icon = if completed, do: "✔️", else: "⭕️"
    "#{status_icon} #{text}"
  end

	def call(history,info, opts \\ []) do
		#IO.puts("openai call")  # Logging when the server call is made
		#raise('we should have seen a print')
	    %{
	      "model" => @model,
	      "messages" => Enum.concat([
	        %{"role" => "system", "content" => generate_prompt(info)},
	      ], history),
	      "temperature" => 0.7
	    }
	    |> Jason.encode!()
	    |> request(opts)
	    |> IO.inspect(label: "OpenAi Text")
	    |> parse_response()
	end

  defp parse_response({:ok, %Finch.Response{body: body}}) do
    messages =
      Jason.decode!(body)
      |> Map.get("choices", [])
      |> Enum.reverse()

      |> IO.inspect(label: "OpenAi Messages")

    case messages do
      [%{"message" => message}|_] -> message
      _ -> "{}"
    end
  end

  defp parse_response(error) do
    error
  end

  defp request(body, _opts) do
    Finch.build(:post, "https://api.openai.com/v1/chat/completions", headers(), body)
    |> Finch.request(AiAssistant.Finch)
  end

  defp headers do
    [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{Application.get_env(:ai_assistant, :open_ai_api_key)}"},
    ]
  end
end
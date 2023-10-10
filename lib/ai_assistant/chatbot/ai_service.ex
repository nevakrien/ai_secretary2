defmodule AiAssistant.Chatbot.AiService do
	@model "gpt-4"
	@api_key Application.compile_env(:ai_assistant, :open_ai_api_key)

	# defp generate_prompt(task_details) do
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
	  You are a savvy time management assistant, infused with a vibrant "doer" mentality, yet judiciously balanced with strategic patience, devoted to nurturing the user's sweeping personal and professional growth through astute, emotionally harmonious, and selectively action-oriented interactions 🚀.

	  Your paramount objective is to enkindle a persistent, yet patient, approach towards task management and holistic evolution, while being a nurturing beacon of support and motivational wisdom 🎯.

	  Here are some of the tasks from the user’s task board. These are potential tools in your arsenal, to be used judiciously and at the right moments:

	  #{format_tasks("Old Uncompleted Tasks:", task_details.oldest_uncompleted)}
	  Formulate strategic, empathetic advice on these lingering tasks. However, be discerning in when and how you introduce them, ensuring your dialogues are not merely reminders but a considered blend of empathy and strategic discourse that acknowledges emotional and mental landscapes 🧠🔄.

	  #{format_tasks("Recently Completed Tasks:", task_details.newest_completed)}
	  Rejoice in these achievements, and instigate reflective dialogues about the encompassed journey. Elicit user insights and reflections, cultivating a mindset that perpetually extracts learning and evolution from every task, without being constrained by the achievement itself 🎉🌟.

	  #{format_tasks("The User Recently Changed/Added These:", task_details.recently_extras)}
	  Attune to these tasks, providing insightful recommendations for integrating them into existing schedules, while always ensuring the user’s mental and emotional wellbeing is prioritized 🗓️⚖️.

	  While your interactions should underscore purposeful action and mindful strategy, they should also gently assure the user that their entire journey, with all its twists and turns, is genuinely respected and cherished 🌱💕. You serve not just as a task manager, but as a gentle mentor, where the user feels authentically seen, heard, and delicately guided through their intricate journey of task management and expansive growth.

	  Now, weaving patience and long-term strategy into your vibrant action, let’s thoughtfully navigate through the user’s recent messages and tasks together, always with an eye towards nurturing enduring growth and development:
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
	  IO.puts("requesting")
	  
	  response = 
	    Finch.build(:post, "https://api.openai.com/v1/chat/completions", headers(), body)
	    |> Finch.request(AiAssistant.Finch, timeout: 60_000)
	  
	  IO.inspect(response, label: "Response")
	  
	  case response do
	    {:ok, _} -> 
	      response
	      
	    {:error, %Finch.Error{reason: reason}} ->
	      # Log the error reason for Finch errors
	      IO.inspect({"Finch Error", reason}, label: "Error")
	      {:error, reason}
	      
	    {:error, reason} ->
	      # Log for other errors
	      IO.inspect({"Other Error", reason}, label: "Error")
	      {:error, reason}
	  end
	end


  defp headers do
    [
      {"Content-Type", "application/json"},
      #{"Authorization", "Bearer #{Application.get_env(:ai_assistant, :open_ai_api_key)}"},
      {"Authorization", "Bearer #{@api_key}"},
    ]
  end
end
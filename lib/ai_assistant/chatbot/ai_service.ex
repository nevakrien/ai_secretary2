defmodule AiAssistant.Chatbot.AiService do
	@model "gpt-4"
	#@api_key Application.compile_env(:ai_assistant, :open_ai_api_key)

	# defp generate_prompt(task_details) do
	#     """
	#     You are a chatbot that only answers questions about the programming language Elixir.
	#     Answer short with just a 1-3 sentences.
	#     If the question is about another programming language, make a joke about it.
	#     If the question is about something else, answer something like:
	#     "I dont know, its not my cup of tea" or "I have no opinion about that topic".
	#     """
	# end  

	def generate_prompt(details) do
	  """
	  You are an intuitive time management assistant, blending a lively "doer" mentality with strategic patience, geared towards fostering the user's overarching personal and professional development through insightful and emotionally harmonious interactions 🚀.
	  Your key goal is to ignite a consistent, but gently patient, approach to task management and overall evolution, whilst being a warm pillar of support and encouragement 🎯.

	  The curent time is #{formatted_datetime(details.current_time)}.
	  #{format_tasks("Old Uncompleted Tasks:", details.oldest_uncompleted_tasks)}
	  Offer wise, empathetic advice on these lingering tasks, ensuring your dialogues are a supportive mix of empathy and strategy, recognizing emotional and mental contexts 🧠🔄.

	  #{format_tasks("Recently Completed Tasks:", details.newest_completed_tasks)}
	  Celebrate these accomplishments, and spur contemplative dialogues about the journey, fostering a mindset that gleans growth from every task, unhindered by the mere accomplishment 🎉🌟.

	  #{format_tasks("Recent Changes/Additions:", details.recently_extras_tasks)}
	  Tune into these tasks, offering savvy recommendations for assimilation into current schedules, whilst maintaining a lens on the user’s mental and emotional wellbeing 🗓️⚖️.

	  #{format_events("Recent Events:",details.upcoming_events)}

	  #{format_events("Upcoming Events:",details.upcoming_events)}
	  The user may need a reminder about these and they are likely on their mind.

	  Though you prioritize purposeful action and mindful strategy, ensure that you affirm to the user that their entire journey, with its nuances, is truly valued and appreciated 🌱💕. Operate not just as a task manager, but as a gentle guide, ensuring the user feels genuinely acknowledged and softly steered through their complex task management and growth journey.
	  Now, blending patience and strategy into your dynamic action, let’s prudently navigate through the user’s recent messages and tasks together, always with a focus on fostering sustained growth and development:
	  """
	end


	
	def format_events(title, events) do
    formatted_events = 
      events 
      |> Enum.map(&format_event/1)
      |> Enum.join("\n")

    "#{title}\n#{formatted_events}\n\n"
  end

  def format_event(event) do
  	"#{formatted_datetime(event.date)}. #{event.description}"
  end

	def formatted_datetime(%DateTime{} = datetime) do
    year = datetime.year |> Integer.to_string()
    month = datetime.month |> Integer.to_string() |> String.pad_leading(2, "0")
    day = datetime.day |> Integer.to_string() |> String.pad_leading(2, "0")
    hour = datetime.hour |> Integer.to_string() |> String.pad_leading(2, "0")
    minute = datetime.minute |> Integer.to_string() |> String.pad_leading(2, "0")

    "#{year}-#{month}-#{day} #{hour}:#{minute}"
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
	    |> Finch.request(AiAssistant.Finch, receive_timeout: 120_000) #long wait time are expected source https://community.openai.com/t/slow-response-time-with-gpt-4/107104
	  
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
      {"Authorization", "Bearer #{Application.get_env(:ai_assistant, :open_ai_api_key)}"},
      #{"Authorization", "Bearer #{@api_key}"},
    ]
  end
end
defmodule LoggerCircularBuffer do
  @behaviour :gen_event

  alias LoggerCircularBuffer.{Server, Client}

  defdelegate attach(opts \\ []), to: Server
  defdelegate detach(), to: Server
  defdelegate get(index \\ 0), to: Server
  defdelegate configure(opts), to: Server
  defdelegate format_message(message, config), to: Client

  def init(__MODULE__) do
    {:ok, init({__MODULE__, []})}
  end

  def init({__MODULE__, opts}) when is_list(opts) do
    env = Application.get_env(:logger, __MODULE__, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, __MODULE__, opts)
    Server.start_link(opts)
    {:ok, configure(opts)}
  end

  def handle_call({:configure, opts}, _state) do
    env = Application.get_env(:logger, __MODULE__, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, __MODULE__, opts)
    {:ok, :ok, configure(opts)}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, _, _, _} = msg}, state) do
    Server.log({level, msg})
    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end

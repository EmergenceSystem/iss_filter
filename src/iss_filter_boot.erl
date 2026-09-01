-module(iss_filter_boot).
-behaviour(application).
-behaviour(supervisor).
-export([start/2, stop/1, init/1]).

start(_Type, _Args) ->
    {ok, Pid} = supervisor:start_link({local, iss_filter_boot_sup}, ?MODULE, []),
    _ = application:ensure_all_started(em_filter),
    _ = em_filter:start_agent(iss_filter, iss_filter_app,
          #{pop_port => 9570,
            query_port => 9571,
            capabilities => iss_filter_app:base_capabilities(),
            pop_peers => [{"localhost", 9100}],
            pop_role => leaf}),
    {ok, Pid}.

stop(_State) -> ok.

init([]) ->
    {ok, {#{strategy => one_for_one, intensity => 1, period => 5}, []}}.

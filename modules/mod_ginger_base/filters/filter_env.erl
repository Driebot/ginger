-module(filter_env).

-export([
    env/2
]).

-include("zotonic.hrl").

%% Check environment, dev/acc/prod
%% usage {{ 0|env }}
env(_, _Context) ->
    ginger_environment:get(Context).

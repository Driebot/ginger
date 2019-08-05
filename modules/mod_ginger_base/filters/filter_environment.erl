-module(filter_environment).
-author("Driebit <info@driebit.nl>").
-export([environment/2]).
-include("zotonic.hrl").

environment(Environment, Context) ->
    case Environment of
        "dev" ->
            case ginger_environment:is_test(Context) of
                false ->
                    ginger_environment:is_dev(Context);
                true ->
                    false
            end;
        "test" ->
            ginger_environment:is_test(Context);
        "acceptance" ->
            ginger_environment:is_acc(Context);
        "production" ->
            ginger_environment:is_prod(Context);
        _ ->
            false
    end.

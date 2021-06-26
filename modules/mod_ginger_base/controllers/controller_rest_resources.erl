-module(controller_rest_resources).

-export([ init/1
        , is_authorized/2
        , service_available/2
        , malformed_request/2
        , allowed_methods/2
        , resource_exists/2
        , delete_resource/2
        , content_types_accepted/2
        , content_types_provided/2
        , to_json/2
        , process_post/2
        , process_put/2
        ]
       ).

-include("controller_webmachine_helper.hrl").
-include("zotonic.hrl").
-include_lib("eunit/include/eunit.hrl").

%% NB: the Webmachine documenation uses "context" where we use "state",
%% we reserve "context" for the way it's used by Zotonic/Ginger.
-record(state, { mode = undefined
               , path_info = undefined
               , context = undefined
               , rsc_id = undefined :: m_rsc:resource()
               }
       ).

%%%-----------------------------------------------------------------------------
%%% Resource functions
%%%-----------------------------------------------------------------------------

init(Args) ->
    Mode = proplists:get_value(mode, Args),
    PathInfo = proplists:get_value(path_info, Args, undefined),
    {ok, #state{mode = Mode, path_info = PathInfo}}.

service_available(Req, State) ->
    Context = z_context:continue_session(z_context:new(Req, ?MODULE)),
    {true, Req, State#state{context = Context}}.

malformed_request(Req, State = #state{mode = document, path_info = id}) ->
    case wrq:path_info(id, Req) of
        undefined ->
            {true, Req, State};
        Id ->
            {false, Req, State#state{rsc_id = Id}}
    end;
malformed_request(Req, State) ->
    {false, Req, State}.

is_authorized(Req, State) ->
    %% Auth checks are only necessary for these methods.
    case lists:member(wrq:method(Req), ['POST', 'PUT', 'DELETE']) of
        false ->
            {true, Req, State};
        true ->
            Context = State#state.context,
            case z_acl:user(Context) of
                undefined ->
                    %% Return a 403 instead of a 401 as we don't use HTTP authentication
                    {{halt, 403}, Req, Context};
                _Id ->
                    {true, Req, State}
            end
    end.

allowed_methods(Req, State) ->
    {['GET', 'POST', 'PUT', 'DELETE', 'HEAD'], Req, State}.

resource_exists(Req, State = #state{mode = collection}) ->
    {true, Req, State};
resource_exists(Req, State = #state{mode = document, path_info = id}) ->
    Context = State#state.context,
    {m_rsc:exists(State#state.rsc_id, Context), Req, State};
resource_exists(Req, State = #state{mode = document, path_info = path}) ->
    Context = State#state.context,
    case path_to_id(wrq:path_info(path, Req), Context) of
        {ok, Id} ->
            {m_rsc:exists(Id, Context), Req, State#state{rsc_id = Id}};
        {error, _} ->
            {false, Req, State}
    end.

content_types_accepted(Req, State) ->
    {[{"application/json", process_put}], Req, State}.

content_types_provided(Req, State) ->
    {[{"application/json", to_json}], Req, State}.

delete_resource(Req, State = #state{mode = document}) ->
    ok = m_rsc:delete(State#state.rsc_id, State#state.context),
    {true, Req, State}.

to_json(Req, State = #state{mode = collection}) ->
    try
        Context = State#state.context,
        Args = search_query:parse_request_args(
                 proplists_filter(
                   fun (Key) -> lists:member(Key, supported_search_args()) end,
                   wrq:req_qs(Req)
                  )
                ),
        EdgePath = m_ginger_rest:parse_path(
                     proplists:get_value("edge_path", wrq:req_qs(Req), "")),
        Ids = z_search:query_(Args, Context),
        Json = jsx:encode([m_ginger_rest:with_deep_edges(
                             m_ginger_rest:rsc(Id, Context), EdgePath, Context)
                           || Id <- Ids, m_rsc:is_visible(Id, Context)
                          ]),
        {Json, Req, State}
    catch
        _:Error ->
            Msg = io_lib:format("An error occurred while fetching the resources: ~p",
                                [Error]),
            MsgWithStackTrace = io_lib:format("~s~n~p", [Msg, erlang:get_stacktrace()]),
            lager:error(MsgWithStackTrace),
            {{halt, 500}, wrq:set_resp_body(Msg, Req), State}
    end;
to_json(Req, State = #state{mode = document}) ->
    try
        Id = State#state.rsc_id,
        Context = State#state.context,
        EdgePath = m_ginger_rest:parse_path(
                     proplists:get_value("edge_path", wrq:req_qs(Req), "")),
        case m_rsc:is_visible(Id, Context) of
            false ->
                {{halt, 401}, Req, State};
            true  ->
                Rsc = m_ginger_rest:rsc(Id, Context),
                {jsx:encode(
                   m_ginger_rest:with_deep_edges(Rsc, EdgePath, Context)), Req, State}
        end
    catch
        _:Error ->
            Msg = io_lib:format("An error occurred while fetching the resource: ~p",
                                [Error]),
            MsgWithStackTrace = io_lib:format("~s~n~p", [Msg, erlang:get_stacktrace()]),
            lager:error(MsgWithStackTrace),
            {{halt, 500}, wrq:set_resp_body(Msg, Req), State}
    end.

process_post(Req, State = #state{mode = collection}) ->
    try
        Context = State#state.context,
        %% Create resource
        {Body, Req1} = wrq:req_body(Req),
        Data = jsx:decode(Body, [return_maps, {labels, atom}]),
        Props = lists:foldl(fun process_props/2, [], maps:to_list(Data)),
        {ok, Id} = m_rsc:insert(Props, Context),
        %% Create edges
        lists:foreach(
          fun (Edge) ->
                  {ok, PredicateId} = m_rsc:name_to_id(maps:get(predicate, Edge), Context),
                  {ok, _EdgeId} = m_edge:insert(Id, PredicateId, maps:get(object, Edge), Context)
          end,
          maps:get(edges, Data, [])
         ),
        %% Set "Location" and "Content-Type" header
        Headers = [{"Location", "/data/resources/" ++ erlang:integer_to_list(Id)},
                   {"Content-Type", "application/json"}
                  ],
        Req2 = wrq:set_resp_headers(Headers, Req1),
        Rsc = m_ginger_rest:with_deep_edges(m_ginger_rest:rsc(Id, Context), [[]], Context),
        %% Done
        {{halt, 201}, wrq:set_resp_body(jsx:encode(Rsc), Req2), State}
    catch
        throw:{{error, nocategory}, _} ->
            Msg = "Category is missing from the request body",
            lager:error(Msg),
            {{halt, 400}, wrq:set_resp_body(Msg, Req), State};
        _:Error ->
            Msg = io_lib:format("An error occurred while storing the new resource: ~p",
                                [Error]),
            MsgWithStackTrace = io_lib:format("~s~n~p", [Msg, erlang:get_stacktrace()]),
            lager:error(MsgWithStackTrace),
            {{halt, 500}, wrq:set_resp_body(Msg, Req), State}
    end.

process_put(Req, State = #state{mode = document, path_info = id}) ->
    try
        Context = State#state.context,
        %% Update resource
        Id = State#state.rsc_id,
        {Body, Req1} = wrq:req_body(Req),
        Data = jsx:decode(Body, [return_maps, {labels, atom}]),
        Props = lists:foldl(fun process_props/2, [], maps:to_list(Data)),
        EscapeText = true,
        case m_rsc:update(Id, Props, EscapeText, Context) of
            {ok, _} ->
                {{halt, 201}, Req1, State};
            {error, _} ->
                {{halt, 400}, Req1, State}
        end
    catch
        _:Error ->
            Msg = io_lib:format("An error occurred while patching the resource: ~p",
                                [Error]),
            MsgWithStackTrace = io_lib:format("~s~n~p", [Msg, erlang:get_stacktrace()]),
            lager:error(MsgWithStackTrace),
            {{halt, 500}, wrq:set_resp_body(Msg, Req), State}
    end.


%%%-----------------------------------------------------------------------------
%%% Internal functions
%%%-----------------------------------------------------------------------------

language_codes() ->
    sets:from_list([en, nl, zh, fr, de, it]).

process_props({edges, _}, Acc) ->
    Acc;
process_props({properties, Value}, Acc) ->
    lists:foldl(fun process_props/2, [], maps:to_list(Value)) ++ Acc;
process_props({Key, Value}, Acc) when is_map(Value)->
    Keys = sets:from_list(maps:keys(Value)),
    case sets:is_disjoint(Keys, language_codes()) of
        false ->
            trans({Key, Value}, Acc);
        true ->
            [{Key, Value}, Acc]
    end;
process_props(Value, Acc) ->
    [Value | Acc].

trans({Key, Value}, Acc) when is_map(Value) ->
    [{Key, {trans, maps:to_list(Value)}} | Acc];
trans({Key, Value}, Acc) ->
    [{Key, Value} | Acc].

supported_search_args() ->
    ["cat", "hasobject", "hassubject", "sort"].


proplists_filter(Filter, List) ->
    lists:foldr(
      fun (Key, Acc) ->
              case Filter(Key) of
                  true ->
                      Acc;
                  false ->
                      proplists:delete(Key, Acc)
              end
      end,
      List,
      proplists:get_keys(List)
     ).

path_to_id("/", Context) ->
    m_rsc:name_to_id("home", Context);
path_to_id(Path, Context) ->
    case string:tokens(Path, "/") of
        ["page", Id | _] ->
            {ok, erlang:list_to_integer(Id)};
        [_Language, "page", Id | _] ->
            {ok, erlang:list_to_integer(Id)};
        _ ->
            case m_rsc:page_path_to_id(Path, Context) of
                {redirect, Id} ->
                    {ok, Id};
                Result ->
                    Result
            end
    end.

%%%-----------------------------------------------------------------------------
%%% Tests
%%%-----------------------------------------------------------------------------

init_test_() ->
    [ fun () ->
              Map = [{mode, collection}, {path_info,id}],
              {ok, State} = init(Map),
              collection = State#state.mode,
              id = State#state.path_info,
              ok
      end
    ].

allowed_methods_test_() ->
    [ fun () ->
              {Methods, _, _} = allowed_methods(req, state),
              ?assert(lists:member('GET', Methods)),
              ?assert(lists:member('POST', Methods)),
              ?assert(lists:member('DELETE', Methods)),
              ?assert(lists:member('HEAD', Methods)),
              ?assert(lists:member('PUT', Methods)),
              ?assertEqual(5, erlang:length(Methods)),
              ok
      end
    ].

malformed_request_test_() ->
    {Setup, Cleanup} = controller_rest:setup_cleanup([wrq]),
    { setup, Setup, Cleanup
      %% tests
    , [ fun () ->
                {false, _, _} =
                    malformed_request(req, #state{mode = collection}),
                ok
        end
      , fun () ->
                {false, _, _} =
                    malformed_request(req, #state{ mode = document
                                                 , path_info = path
                                                 }
                                     ),
                ok
        end
      ]
    }.

resource_exists_test_() ->
    {Setup, Cleanup} = controller_rest:setup_cleanup([z_context, wrq, m_rsc, m_edge]),
    { setup, Setup, Cleanup
      %% tests
    , [ fun () ->
                State = #state{mode = collection},
                {true, _, _} = resource_exists(req, State),
                ok
        end
      , fun () ->
                State = #state{mode = document, path_info = id},
                meck:expect(z_context, new, 2, ok),
                meck:expect(wrq, path_info, 2, "1"),
                meck:expect(m_rsc, exists, 2, false),
                {false, _, _} = resource_exists(req, State),
                meck:expect(m_rsc, exists, 2, true),
                {true, _, _} = resource_exists(req, State),
                ok
        end
      , fun () ->
                State = #state{mode = document, path_info = path},
                meck:expect(z_context, new, 2, ok),
                meck:expect(wrq, path_info, 2, "/"),
                meck:expect(m_rsc, name_to_id, 2, {ok, 1}),
                meck:expect(m_rsc, exists, 2, true),
                {true, _, _} = resource_exists(req, State),
                meck:expect(m_rsc, exists, 2, false),
                {false, _, _} = resource_exists(req, State),
                meck:expect(m_rsc, name_to_id, 2, {error, whatever}),
                {false, _, _} = resource_exists(req, State),
                ok
        end
      ]
    }.

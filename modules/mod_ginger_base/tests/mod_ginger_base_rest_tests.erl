-module(mod_ginger_base_rest_tests).

-include_lib("eunit/include/eunit.hrl").
-include_lib("zotonic.hrl").

get_existing_resource_test_() ->
    {ok, Id} = m_rsc:insert([{category, text}, {title, <<"Title">>}, {published, true}], context()),
    {setup,
     %% setup
     fun () ->
             Req = #wm_reqdata{
                      req_cookie = "yumyum",
                      path_info = dict:from_list([ {id, erlang:integer_to_list(Id)}
                                                 , {zotonic_host, testsandboxdb}
                                                 ]
                                                )
                     },
             {ok, State} = controller_rest_resources:init([ #{ mode => document
                                                             , path_info => id
                                                             }
                                                          ]),
             {Req, State}
     end,
     %% cleanup
     fun (_) ->
             m_rsc:delete(Id, context())
     end,
     %% tests/instantiator
     fun ({Req, State}) ->
             {Result, Req1, State1} = controller_rest_resources:service_available(Req, State),
             {Result1, Req2, State2} = controller_rest_resources:malformed_request(Req1, State1),
             {Result2, Req3, State3} = controller_rest_resources:resource_exists(Req2, State2),
             {Result3, _Req4, _State4} = controller_rest_resources:to_json(Req3, State3),
             Map = jsx:decode(Result3, [{labels, atom}, return_maps]),
             %% Assertions
             [ ?_assertEqual(true, Result),
               ?_assertEqual(false, Result1),
               ?_assertEqual(true, Result2),
               ?_assertEqual(Id, maps:get(id, Map, undefined))
             ]
     end
    }.

context() ->
    z_acl:sudo(z_context:new(testsandboxdb)).

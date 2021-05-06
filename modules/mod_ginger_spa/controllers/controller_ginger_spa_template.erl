%% @copyright Driebit BV 2021
%% @doc Controller to render templates. Post arguments via the query arguments.

-module(controller_ginger_spa_template).

-export([init/1, service_available/2, charsets_provided/2, content_types_provided/2]).
-export([allowed_methods/2, resource_exists/2]).
-export([process_post/2, provide_content/2]).

-include_lib("controller_webmachine_helper.hrl").
-include_lib("include/zotonic.hrl").

init(DispatchArgs) -> {ok, DispatchArgs}.

service_available(ReqData, DispatchArgs) when is_list(DispatchArgs) ->
    Context1 = z_context:new_request(ReqData, DispatchArgs, ?MODULE),
    ?WM_REPLY(true, Context1).

allowed_methods(ReqData, Context) ->
    {[ 'POST', 'GET', 'HEAD' ], ReqData, Context}.

charsets_provided(ReqData, Context) ->
    {[{"utf-8", fun(X) -> X end}], ReqData, Context}.

content_types_provided(ReqData, Context) ->
    {[{"text/plain", provide_content}], ReqData, Context}.

resource_exists(ReqData, Context) ->
    Context1 = ?WM_REQ(ReqData, Context),
    Context2 = z_context:ensure_all(Context1),
    ?WM_REPLY(true, Context2).

process_post(ReqData, Context) ->
    Context1 = ?WM_REQ(ReqData, Context),
    Result = render(Context1),
    ReqData1 = wrq:set_resp_body(Result, ReqData),
    {{halt, 200}, ReqData1, Context}.

provide_content(ReqData, Context) ->
    Context1 = ?WM_REQ(ReqData, Context),
    Result = render(Context1),
    ?WM_REPLY(Result, Context1).

render(Context) ->
    Template = z_context:get_q("*", Context),
    case is_viewable(Template, Context) of
        true ->
            Vars = [
                {is_spa_render, true},
                {id, m_rsc:rid(z_context:get_q("id", Context), Context)}
            ],
            Template1 = case is_catinclude(Context) of
                true -> {cat, Template};
                false -> Template
            end,
            {Data, _} = z_template:render_to_iolist(Template1, Vars, Context),
            iolist_to_binary(Data);
        false ->
            lager:info("[~p] Denied render of template \"~s\"", [ z_context:site(Context), Template ]),
            <<>>
    end.

is_catinclude(Context) ->
    z_convert:to_bool(z_context:get_q("catinclude", Context)).

is_viewable("/" ++ _, _Context) -> false;
is_viewable("public/" ++ _, _Context) -> true;
is_viewable("member/" ++ _, Context) -> z_auth:is_auth(Context);
is_viewable(T, Context) when is_list(T) -> z_acl:is_admin(Context).

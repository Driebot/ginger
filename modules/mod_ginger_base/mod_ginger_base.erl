%% @author Driebit <info@driebit.nl>
%% @copyright 2015

-module(mod_ginger_base).
-author("Driebit <info@driebit.nl>").

-mod_title("Ginger Base").
-mod_description("Ginger Base").
-mod_prio(250).
-mod_depends([mod_content_groups, mod_acl_user_groups]).

-mod_schema(11).

-export([
    init/1,
    event/2,
    manage_schema/2,
    observe_admin_rscform/3,
    observe_custom_pivot/2,
    observe_rsc_get/3,
    observe_search_query/2,
    observe_security_headers/2,
    observe_acl_is_owner/2
]).

-include("zotonic.hrl").
-include_lib("modules/mod_admin/include/admin_menu.hrl").

%% @doc Initialize mod_ginger_base
-spec init(#context{}) -> ok.
init(Context) ->
    ginger_config:install_config(Context),
    z_pivot_rsc:define_custom_pivot(ginger_search, [{is_unfindable, "boolean not null default false"}], Context).

%% @doc When ACL is enabled, create a default user in the editors group
manage_schema(_Version, _Context) ->
    #datamodel{
        categories=[
            {agenda, query, [
                {title, {trans, [
                    {nl, <<"Agenda">>},
                    {en, <<"Agenda">>}]}},
                {language, [en, nl]}
            ]},
            {location_query, query, [
                {title, {trans, [
                    {nl, <<"Locatie zoekopdracht">>},
                    {en, <<"Location search query">>}]}},
                {language, [en, nl]}
            ]}
        ],
        resources = [
            % {uniquename, category, [
            %     {propname, propvalue}
            % ]},
            {editor_dev, person, [
                {title, "Redacteur"},
                {name_first, "Redacteur"},
                {email, "redactie@ginger.nl"}
            ]},
            {fallback, image, [
                {title, "Fallback image"}
            ]},
            {footer_menu, menu, [
                {title, "Footer menu"}
            ]},
            {home, collection, [
                {title, "Homepage"}
            ]},
            {page_404, text, [
                {title, {trans, [
                    {nl, <<"404, Deze pagina bestaat niet">>},
                    {en, <<"404, This page does not exist">>}]}},
                {language, [en, nl]},
                {is_unfindable, true},
                {seo_noindex, true}
            ]}
        ],
        predicates = [
            {subnavigation, [
                {title, {trans, [
                    {nl, <<"Subnavigatie">>},
                    {en, <<"Subnavigation">>}]}},
                {language, [en, nl]}
            ], [
                {content_group, collection}
            ]},
            {hasbanner, [
                {title, {trans, [
                    {nl, <<"Banner">>},
                    {en, <<"Banner">>}]}},
                {language, [en, nl]}
            ], [
                {content_group, image},
                {collection, image},
                {query, image}
            ]},
            {header, [
                {title, {trans, [
                    {nl, <<"Header">>},
                    {en, <<"Header">>}]}},
                {language, [en, nl]}
            ], [
                {content_group, media}
            ]},
            {hasicon, [
                {title, {trans, [
                    {nl, <<"Icoon">>},
                    {en, <<"Icon">>}]}},
                {language, [en, nl]}
            ], [
                {category, image}
            ]},
            {rsvp, [
                {title, {trans, [
                    {nl, <<"RSVP">>},
                    {en, <<"RSVP">>}]}},
                {language, [en, nl]}
            ], [
                {person, event}
            ]}
        ],
        edges = [
            {editor_dev, hasusergroup, acl_user_group_editors}
        ],
        data = [
            {acl_rules, [
                %% Anonymous can view everything
                {rsc, [
                    {acl_user_group_id, acl_user_group_anonymous},
                    {actions, [view]}
                ]},
                %% Members can edit their own profile.
                {rsc, [
                    {acl_user_group_id, acl_user_group_members},
                    {actions, [update, link]},
                    {category_id, person},
                    {is_owner, true}
                ]},
                %% Members can upload media, for instance a profile picture.
                {rsc, [
                    {acl_user_group_id, acl_user_group_members},
                    {actions, [insert]},
                    {category_id, media}
                ]},
                {rsc, [
                    {acl_user_group_id, acl_user_group_members},
                    {actions, [update, delete]},
                    {category_id, media},
                    {is_owner, true}
                ]},
                %% Editors can edit everything, including resources created by other editors
                {rsc, [
                    {acl_user_group_id, acl_user_group_editors},
                    {actions, [view, insert, update, delete, link]}
                ]},
                %% Editors can access the admin
                {module, [
                    {acl_user_group_id, acl_user_group_editors},
                    {actions, [use]},
                    {module, mod_admin}
                ]},
                %% Editors can configure the menu
                {module, [
                    {acl_user_group_id, acl_user_group_editors},
                    {actions, [use]},
                    {module, mod_menu}
                ]}
            ]}
        ]
    }.

%% @doc Users without access to the admin should not be able to view unpublished
%%      resources
%%observe_acl_is_allowed(#acl_is_allowed{action=view, object=Id}, Context) ->
%%    ginger_acl:can_view(Id, Context);
%%observe_acl_is_allowed(#acl_is_allowed{}, _Context) ->
%%    undefined.

%% @doc Handle the submit event of a new comment
event(#submit{message={newcomment, Args}, form=FormId}, Context) ->
    ExtraActions = proplists:get_all_values(action, Args),
    {id, Id} = proplists:lookup(id, Args),
    case z_auth:is_auth(Context) of
        false ->
            Name = z_context:get_q_validated("name", Context),
            Email = z_context:get_q_validated("mail", Context);
        true ->
            Name = "",
            Email = ""
    end,
    Message = z_context:get_q_validated("message", Context),
    Is_visible = case m_config:get_value(comments, moderate, Context) of <<"1">> -> false; _Else -> true end,
    case m_comment:insert(Id, Name, Email, Message, Is_visible, Context) of
        {ok, CommentId} ->
            CommentsListElt = proplists:get_value(comments_list, Args, "comments-list"),
            CommentTemplate = proplists:get_value(comment_template, Args, "_comments_comment.tpl"),
            Comment = m_comment:get(CommentId, Context),
            Props = [
                {id, Id},
                {comment, Comment},
                {creator, m_rsc:p(Id, creator_id, Context)},
                {hidden, true}
            ],
            Html = z_template:render(CommentTemplate, Props, Context),
            Context1 = z_render:insert_bottom(CommentsListElt, Html, Context),
            Context2 = case Is_visible of
			   true ->
             AllActions = lists:merge([
					      {set_value, [{selector, "#"++FormId++" textarea[name=\"message\"]"}, {value, ""}]},
					      {set_value, [{selector, "#"++FormId++" input[name=\"message\"]"}, {value, ""}]},
					      {fade_in, [{target, "comment-"++integer_to_list(CommentId)}]}
					     ], ExtraActions),
			       z_render:wire(AllActions, Context1);
			   false ->
			       Context1
		       end,
            case z_convert:to_bool(proplists:get_value(do_redirect, Args, true)) of
                true -> z_render:wire({redirect, [{location, "#comment-"++integer_to_list(CommentId)}]}, Context2);
                false -> Context2
            end;
        {error, _} ->
            Context
    end;
event(#postback{message={map_infobox, _Args}}, Context) ->
    Ids = z_context:get_q(ids, Context),
    Render = case z_context:get_q(data, Context) of
                        [] ->
                            z_template:render("map/map-infobox.tpl", [{results, Ids}], Context);
                        Data ->
                            z_template:render("map/map-infobox-data-item.tpl", [{item, Data}], Context)
                end,
    Element = z_context:get_q(element, Context),

    EscapedRender = z_utils:js_escape(iolist_to_binary(Render)),
    JS = erlang:iolist_to_binary(
        [
            <<"$('#">>,
            Element,
            <<"').data('ui-googlemap').showInfoWindow(">>,
            z_convert:to_binary(lists:last(Ids)),
            <<", \"">>,
            z_convert:to_binary(EscapedRender),
            <<"\");">>
        ]
    ),
    z_render:wire({script, [{script, JS}]}, Context).

%% @doc When a resource is persisted in the admin, update granularity for
%%      granular date fields.
observe_admin_rscform(#admin_rscform{}, Post, _Context) ->
    ginger_date:update_granularity(Post).

observe_custom_pivot({custom_pivot, Id}, Context) ->
    Excluded = z_convert:to_bool(m_rsc:p(Id, is_unfindable, z_acl:sudo(Context))),
    {ginger_search, [{is_unfindable, Excluded}]}.

%% @doc Add some virtual properties
-spec observe_rsc_get(#rsc_get{}, list(tuple()), #context{}) -> list(tuple()).
observe_rsc_get(#rsc_get{}, Props, _Context) ->
    case proplists:get_value(rights, Props) of
        undefined ->
            Props;
        Rights ->
            %% This is used by mod_ginger_rdf
            Props ++ [{license, m_creative_commons:url_for(Rights)}]
    end.

observe_search_query(#search_query{search={ginger_search, _Args}}=Q, Context) ->
    ginger_search:search_query(Q, Context);
observe_search_query(#search_query{search={ginger_geo, _Args}}=Q, Context) ->
    ginger_geo_search:search_query(Q, Context);
observe_search_query(#search_query{search={ginger_geo_nearby, _Args}}=Q, Context) ->
    ginger_geo_search:search_query(Q, Context);
observe_search_query(#search_query{}, _Context) ->
    undefined.

%% @doc Always set the Strict-Transport-Security HTTP header on responses.
%%      This header only has effect on HTTPS, so won't affect any local non-HTTPS environments.
-spec observe_security_headers(#security_headers{}, z:context()) -> proplists:proplist().
observe_security_headers(#security_headers{headers = Headers}, _Context) ->
    [
        {"Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload"}
        | Headers
    ].

%% @doc Authors are owners by default in Ginger
-spec observe_acl_is_owner(#acl_is_owner{}, #context{}) -> boolean() | undefined.
observe_acl_is_owner(#acl_is_owner{user_id = undefined}, _Context) ->
    undefined;
observe_acl_is_owner(#acl_is_owner{id = RscId, user_id = UserId}, Context) ->
    case lists:member(UserId, m_edge:objects(RscId, author, Context)) of
        true -> true;
        false -> undefined
    end.

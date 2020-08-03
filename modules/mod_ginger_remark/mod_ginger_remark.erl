%% @author Driebit <tech@driebit.nl>
%% @copyright 2016

-module(mod_ginger_remark).
-author("Driebit <tech@driebit.nl>").

-mod_title("Ginger remark").
-mod_description("Enables simple adding of resources.").
-mod_depends([mod_ginger_edit]).

-include_lib("zotonic.hrl").

-mod_prio(250).
-mod_schema(13).

-export([
    manage_schema/2,
    observe_rsc_update/3,
    observe_acl_is_allowed/2,
    observe_acl_is_allowed_prop/2,
    observe_rsc_update_done/2,
    notify_followers/2
]).

manage_schema(_Version, Context) ->
    #datamodel{
        categories=[
            {remark, text, [
                {title, {trans, [{nl, <<"Reactie">>},
                                 {en, <<"Remark">>}]}},
                {language, [en,nl]}
            ]}
        ],
        predicates=[
            {follow, [
              {title, {trans, [{nl, <<"Volg">>},
                               {en, <<"Follow">>}]}}
              ], [
              {person, undefined}
            ]}
        ],
        resources=[
            {cg_user_generated, content_group, [
              {title, <<"User generated">>}
            ]}
        ],
        data = [
            {acl_rules, [
                {rsc, [
                    {acl_user_group_id, acl_user_group_members},
                    {actions, [insert, update, link, delete]},
                    {category_id, remark},
                    {content_group_id, m_rsc:rid(cg_user_generated, Context)},
                    {is_owner, true}
                ]}
            ]}
        ]}.

is_owner(Id, #context{user_id=undefined, session_id=SessionId} = Context) ->
    case m_rsc:p_no_acl(Id, session_owner, Context) of
         undefined -> false;
         SessionOwner -> SessionId == SessionOwner
    end.

observe_acl_is_allowed_prop(#acl_is_allowed_prop{action=view, prop=session_owner}, _Context) ->
    false;
observe_acl_is_allowed_prop(#acl_is_allowed_prop{}, _Context) ->
    undefined.

observe_rsc_update(#rsc_update{action=insert},
                   {_IsChanged, UpdateProps},
                   #context{session_id=SessionId, user_id=undefined}) ->
    Props = lists:keystore(session_owner, 1, UpdateProps, {session_owner, SessionId}),
    {true, Props};
observe_rsc_update(#rsc_update{}, Acc, _Context) ->
    Acc.

observe_acl_is_allowed(#acl_is_allowed{action=view, object=RscId},
                       #context{user_id=undefined} = Context) when is_integer(RscId) ->
    case is_owner(RscId, Context) of
        true -> true;
        false -> undefined
    end;
observe_acl_is_allowed(#acl_is_allowed{action=update, object=RscId},
                       #context{user_id=undefined} = Context) when is_integer(RscId) ->
    is_owner(RscId, Context);
observe_acl_is_allowed(#acl_is_allowed{action=insert, object=#acl_edge{subject_id=RscId}},
                       #context{user_id=undefined} = Context) ->
    is_owner(RscId, Context);
observe_acl_is_allowed(#acl_is_allowed{}, _Context) ->
    undefined.

notify_email(Email, Vars, Context) ->
    z_email:send_render(Email, "_email-follow.tpl", Vars, z_acl:sudo(Context)).

notify_followers(RemarkId, Context) ->
    About = m_rsc:o(RemarkId, about, 1, Context),
    {rsc_list, Authors} = m_rsc:o(About, author, Context),
    {rsc_list, Followers} = m_rsc:s(About, follow, Context),

    lists:foreach(
        fun(Author) ->
            Vars = [ {about, About},
                     {remark, RemarkId},
                     {person, Author},
                     {author, "true"}],
            Email = m_rsc:p(Author, email, Context),
            notify_email(Email, Vars, Context)
        end,
        Authors
    ),

    lists:foreach(
        fun(Follower) ->
            Vars = [ {about, About},
                     {remark, RemarkId},
                     {person, Follower}],
            Email = m_rsc:p(Follower, email, Context),
            notify_email(Email, Vars, Context)
        end,
        Followers
    ),
    ok.

is_being_published(#rsc_update_done{post_props = PostProps, pre_props = PreProps}) ->
    PrePublished = proplists:get_value(is_published, PreProps),
    PostPublished = proplists:get_value(is_published, PostProps),
    ((PrePublished == false) or (PrePublished == undefined)) and (PostPublished == true).

% Notify followers, authors that a new remark has been added
observe_rsc_update_done(#rsc_update_done{id = RemarkId, post_is_a = [text,remark]} = RscUpdateDone, Context) ->
    case is_being_published(RscUpdateDone) of
        true ->
            notify_followers(RemarkId, Context);
        false ->
            undefined
    end;
observe_rsc_update_done(#rsc_update_done{}, _Context) ->
    undefined.

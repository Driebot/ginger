%% @author Driebit <info@driebit.nl>
%% @copyright 2015

-module(mod_ginger_base).
-author("Driebit <info@driebit.nl>").

-mod_title("Ginger Base").
-mod_description("Ginger Base").
-mod_prio(250).

-export([
    event/2,
    init/1,
    observe_custom_pivot/2
]).

-include("zotonic.hrl").

%% @doc Initialize mod_ginger_base
-spec init(#context{}) -> ok.
init(Context) ->
    ginger_config:install_config(Context),
    z_pivot_rsc:define_custom_pivot(ginger_findable, [{is_excluded_from_search, "boolean not null default false"}], Context).

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
    end.

observe_custom_pivot({custom_pivot, Id}, Context) ->
    Excluded = z_convert:to_bool(m_rsc:p(Id, is_excluded_from_search, Context)),
    {ginger_findable, [{is_excluded_from_search, Excluded}]}.

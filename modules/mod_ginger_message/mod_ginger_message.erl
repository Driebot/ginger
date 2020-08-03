%% @author Driebit <info@driebit.nl>
%% @copyright 2015

-module(mod_ginger_message).
-author("Driebit <info@driebit.nl>").

-mod_title("Messages").
-mod_description("Send user notification messages by category").
-mod_prio(75).
-mod_schema(1).

-include_lib("zotonic.hrl").

-export([
    manage_schema/2
]).

manage_schema(install, _Context) ->
    #datamodel{
        categories=[
            {message, undefined, [
                {is_unfindable, 1},
                {title, {trans, [
                    {nl, <<"Bericht">>},
                    {en, <<"Message">>}
                ]}}
            ]}
        ],
        predicates = [
            {received_message, [
                {title, {trans, [
                    {nl, <<"Bericht ontvangen">>},
                    {en, <<"Message received">>}
                ]}}
            ], [
                {person, message}
            ]},
            {read_message, [
                {title, {trans, [
                    {nl, <<"Bericht gelezen">>},
                    {en, <<"Message read">>}
                ]}}
            ], [
                {person, message}
            ]},
            {send_message, [
                {title, {trans, [
                    {nl, <<"Verzenden naar">>},
                    {en, <<"Send to">>}
                ]}}
            ], [
                {message, category}
            ]}
        ]
    }.

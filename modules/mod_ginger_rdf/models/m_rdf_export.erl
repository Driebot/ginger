%% @doc Export a Zotonic resource to RDF.
-module(m_rdf_export).

-export([
    to_rdf/2,
    to_rdf/3,
    translations_to_rdf/3,
    with_original_media/4,
    with_thumbnail/4
]).

-include_lib("zotonic.hrl").
-include_lib("../include/rdf.hrl").

-spec to_rdf(m_rsc:resource(), z:context()) -> m_rdf:rdf_resource().
to_rdf(Id, Context) ->
    to_rdf(Id, [schema_org], Context).

%% @doc Export a Zotonic resource to RDF.
%%      Combine:
%%      - properties
%%      - outgoing edges
%%      - media.
-spec to_rdf(m_rsc:resource(), [module()], z:context()) -> m_rdf:rdf_resource().
to_rdf(Id, Ontologies, Context) ->
    Properties = case m_rsc:get_visible(Id, Context) of
        undefined -> [];
        Props -> Props
    end,
    Edges = m_edge:get_edges(Id, Context),
    Types = types(proplists:get_value(category_id, Properties), Context),
    Triples = lists:flatten(
        Types
        ++ properties_to_triples(Properties, Ontologies, Context)
        ++ edges_to_triples(Edges, Ontologies, Context)
    ),
    Result = z_notifier:foldr(#rsc_to_rdf{id = Id}, Triples, Context),
    m_rdf:rdf_resource(m_rsc:p(Id, uri, Context), Result).

properties_to_triples(Properties, Ontologies, Context) ->
    lists:filtermap(
        fun(Property) ->
            case property_to_triples(Property, Properties, Ontologies, Context) of
                [] ->
                    false;
                Triples ->
                    {true, Triples}
            end
        end,
        Properties
    ).

property_to_triples({_, <<>>}, _Properties, _Ontologies, _Context) ->
    [];
property_to_triples({_, undefined}, _Properties,  _Ontologies, _Context) ->
    [];
property_to_triples(Property, Properties, Ontologies, Context) ->
    [Ontology:property_to_triples(Property, Properties, Context) || Ontology <- Ontologies].

edges_to_triples(Edges, Ontologies, Context) ->
    lists:filtermap(
        fun({Predicate, EdgesForPredicate}) ->
            Uri = m_rsc:p(Predicate, uri, Context),
            case lists:flatten([
                Ontology:edge_to_triples(
                    Predicate,
                    Uri,
                    proplists:get_value(subject_id, Edge),
                    proplists:get_value(object_id, Edge),
                    Context
                )
                || Edge <- EdgesForPredicate, Ontology <- Ontologies
            ]) of
                [] ->
                    false;
                List ->
                    {true, List}
            end
        end,
        Edges
    ).

-spec types(m_rsc:resource(), z:context()) -> [m_rdf:triple()].
types(Category, Context) ->
    case get_category_uri(Category, Context) of
        undefined ->
            [];
        _ ->
            [
                #triple{
                    predicate = rdf_property:rdf(<<"type">>),
                    object = get_category_uri(Category, Context)
                }
            ]
    end.

%% @doc Get category URI, starting at the most specific category and falling
%%      back to parent categories
get_category_uri([], _Context) ->
    undefined;
get_category_uri([Category | T], Context) ->
    %% Don't use m_rsc:p(Id, uri, Context) as that will return all URIs, even
    %% including generated ones (http://site.com/id/123). We only want to return
    %% a URI if it has been set explicitly.
    case m_rsc:get_visible(Category, Context) of
        undefined ->
            undefined;
        Props ->
            case proplists:get_value(uri, Props) of
                undefined ->
                    %% Fall back to parent category
                    get_category_uri(T, Context);
                Uri ->
                    Uri
            end
    end;
get_category_uri(Category, Context) ->
    get_category_uri(lists:reverse(m_category:is_a(Category, Context)), Context).

-spec translations_to_rdf(m_rdf:predicate(), proplists:proplist(), z:context()) -> [m_rdf:triple()].
translations_to_rdf(Predicate, Translations, Context) ->
    lists:map(
        fun({Language, Value}) ->
            #triple{
                predicate = Predicate,
                object = #rdf_value{
                    language = Language,
                    value = Value
                }
            }
        end,
        m_ginger_rest:translations(Translations, Context)
    ).

%% @doc Try to find media triples and add them to the set of triples.
-spec with_original_media(m_rsc:resource(), m_rdf:predicate(), [m_rdf:triple()], z:context())
    -> [m_rdf:triple()].
with_original_media(Id, Predicate, Triples, Context) ->
    maybe_add_media(
        fun() ->
            z_media_tag:url(Id, [{use_absolute_url, true}], Context)
        end,
        Predicate,
        Triples
    ).

%% @doc Try to find media triples and add them.
-spec with_thumbnail(m_rsc:resource(), m_rdf:predicate(), [m_rdf:triple()], z:context())
    -> [m_rdf:triple()].
with_thumbnail(Id, Predicate, Triples, Context) ->
    maybe_add_media(
        fun() ->
            z_media_tag:url(Id, [{mediaclass, <<"rdf-thumbnail">>}, {use_absolute_url, true}], Context)
        end,
        Predicate,
        Triples
    ).

-spec maybe_add_media(function(), m_rdf:predicate(), [m_rdf:triple()]) -> [m_rdf:triple()].
maybe_add_media(Fun, Predicate, Triples) ->
    case Fun() of
        {ok, MediaUrl} ->
            Triples ++ [#triple{
                type = resource,
                predicate = Predicate,
                object = MediaUrl
            }];
        {error, _} ->
            Triples
    end.

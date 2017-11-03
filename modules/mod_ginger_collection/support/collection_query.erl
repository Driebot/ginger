%% @doc Collection search query
-module(collection_query).

-export([
    parse_query/3
]).

-include_lib("zotonic.hrl").
-include_lib("mod_ginger_rdf/include/rdf.hrl").

%% @doc Parse Zotonic search query arguments and return Elastic query arguments.
-spec parse_query(list() | binary(), binary(), proplists:proplist()) -> proplists:proplist().
parse_query(Key, Value, QueryArgs) when is_list(Key) ->
    parse_query(list_to_binary(Key), Value, QueryArgs);
parse_query(_Key, [], QueryArgs) ->
    QueryArgs;
parse_query(_Key, <<>>, QueryArgs) ->
    QueryArgs;
parse_query(<<"facets">>, Facets, QueryArgs) ->
    QueryArgs ++ lists:map(fun map_facet/1, Facets);
parse_query(<<"subject">>, Subjects, QueryArgs) ->
    QueryArgs ++ lists:map(
        fun(Subject) ->
            {filter, [<<"dcterms:subject.rdfs:label.keyword">>, Subject]}
        end,
        Subjects
    );
%% Whitelist term filters
parse_query(Term, Values, QueryArgs) when
    Term =:= <<"object_category.keyword">>;
    Term =:= <<"dcterms:spatial.rdfs:label.keyword">>;
    Term =:= <<"dcterms:subject.rdfs:label.keyword">>
->
    QueryArgs ++ lists:map(
        fun(Value) ->
            {filter, [Term, Value]}
        end,
        Values
    );
%% Parse subsets (Elasticsearch types). You can specify multiple per checkbox
%% by separating them with a comma.
parse_query(<<"subset">>, Types, QueryArgs) ->
    AllTypes = lists:foldl(
        fun(Type, Acc) ->
            Acc ++ binary:split(Type, <<",">>, [global])
        end,
        [],
        Types
    ),
    QueryArgs ++ [{filter, [[<<"_type">>, Type] || Type <- AllTypes]}];
parse_query(Key, Range, QueryArgs) when Key =:= <<"dcterms:date">>; Key =:= <<"dcterms:created">> ->
    IncludeMissing = proplists:get_value(<<"include_missing">>, Range, false),
    QueryArgs
        ++ date_filter(Key, <<"gte">>, proplists:get_value(<<"min">>, Range), IncludeMissing)
        ++ date_filter(Key, <<"lte">>, proplists:get_value(<<"max">>, Range), IncludeMissing);
parse_query(<<"edge">>, Edges, QueryArgs) ->
    QueryArgs ++ lists:filtermap(fun map_edge/1, Edges);
parse_query(
    related_to, #{
        <<"_id">> := Id,
        <<"_type">> := Type,
        <<"_source">> := Source
    },
    QueryArgs
) ->
    OrFilters = map_related_to(Source),
    %% Use query_context_filter to have them scored: more matching edges mean
    %% a better matching document.
    [{query_context_filter, OrFilters}, {exclude_document, [Type, Id]} | QueryArgs];
parse_query(<<"license">>, Values, QueryArgs) ->
    QueryArgs ++ [{filter, [[<<"dcterms:license.keyword">>, Value] || Value <- Values]}];
parse_query(is_published, Value, QueryArgs) ->
    %% Resource is published OR it's not a Zotonic resource
    QueryArgs ++ [{filter, [[<<"is_published">>, Value], [<<"_type">>, '<>', <<"resource">>]]}];
parse_query(Key, Value, QueryArgs) ->
    [{Key, Value} | QueryArgs].

map_facet({Name, [{<<"global">>, Props}]}) ->
    %% Nested global aggregation
    {agg, [Name, Props ++ [{<<"global">>, [{}]}]]};
map_facet({Name, [{Type, Props}]}) when is_list(Props) ->
    {agg, [Name, Type, Props]};
map_facet({Name, Props}) ->
    map_facet({Name, [{terms, Props}]}).

map_edge(<<"depiction">>) ->
    %% The collection object has a reproduction OR it's a Zotonic resource
    {true, {filter, [[<<"reproduction.value">>, exists], [<<"_type">>, <<"resource">>]]}};
map_edge(_) ->
    false.

map_related_to(Object) when is_map(Object) ->
    ObjectWithContext = Object#{<<"@context">> => #{
        <<"schema">> => ?NS_SCHEMA_ORG,
        <<"dcterms">> => ?NS_DCTERMS,
        <<"dbpedia-owl">> => ?NS_DBPEDIA_OWL,
        <<"dbo">> => ?NS_DBPEDIA_OWL,
        <<"foaf">> => ?NS_FOAF,
        <<"rdf">> => ?NS_RDF
    }},
    #rdf_resource{triples = Triples} = ginger_json_ld:deserialize(ObjectWithContext),
    lists:foldl(fun map_related_to_property/2, [], Triples).
    
map_related_to_property(#triple{predicate = <<?NS_RDF, "type">>, type = resource, object = Object}, Filters) ->
    [
        [<<"rdf:type.@id.keyword">>, Object],
        [<<"dcterms:subject.@id.keyword">>, Object]
        | Filters
    ];
map_related_to_property(#triple{predicate = <<?NS_DCTERMS, "creator">>, type = resource, object = Object}, Filters) ->
    [[<<"dcterms:creator.@id.keyword">>, '=', Object, #{<<"path">> => <<"dcterms:creator">>}] | Filters];
map_related_to_property(#triple{predicate = <<?NS_DCTERMS, "subject">>, type = resource, object = Object}, Filters) ->
    [[<<"dcterms:subject.@id.keyword">>, Object] | Filters];
map_related_to_property(#triple{predicate = <<?NS_DCTERMS, "spatial">>, type = resource, object = Object}, Filters) ->
    [[<<"dcterms:spatial.@id.keyword">>, Object] | Filters];
map_related_to_property(#triple{}, QueryArgs) ->
    QueryArgs.

date_filter(_Key, _Operator, <<>>, _IncludeMissing) ->
    [];
date_filter(Key, Operator, Value, IncludeMissing) when Operator =:= <<"gte">>; Operator =:= <<"gt">>;
    Operator =:= <<"lte">>; Operator =:= <<"lt">>
->
    DateFilter = [Key, Operator, Value, [{<<"format">>, <<"yyyy">>}]],
    OrFilters = case IncludeMissing of
        true ->
            [DateFilter, [Key, missing]];
        false ->
            DateFilter
    end,
    
    [{filter, OrFilters}].
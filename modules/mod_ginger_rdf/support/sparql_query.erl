%% @doc Build SPARQL queries.
-module(sparql_query).

-export([
    select/1,
    select/2,
    distinct/1,
    resolve_arguments/2,
    and_where/2,
    limit/2,
    offset/2,
    query/1
]).

-include_lib("zotonic.hrl").

-type arguments() :: map().
-type query() :: binary().

-record(sparql_query, {
    select = [] :: [binary()],
    distinct = false :: boolean(),
    where = [] :: [binary()],
    arguments = #{} :: arguments(),
    offset = 0 :: non_neg_integer(),
    limit = 1000 :: pos_integer()
}).

-opaque sparql_query() :: #sparql_query{}.

-export_type([
    sparql_query/0,
    query/0
]).

%% @doc Construct textual SPARQL query.
-spec query(sparql_query()) -> binary().
query(Query) ->
    #sparql_query{
        select = Selects,
        distinct = Distinct,
        where = Where,
        offset = Offset,
        limit = Limit
    } = Query,
    <<"SELECT ", (query_distinct(Distinct))/binary, (ginger_binary:join(Selects, <<" ">>))/binary,
        " { ", (ginger_binary:join(Where, <<" ">>))/binary, " } ",
        " OFFSET ", (integer_to_binary(Offset))/binary,
        " LIMIT ", (integer_to_binary(Limit))/binary
    >>.

%% @doc Construct a SPARQL query with a set of predicates.
-spec select([binary()]) -> sparql_query().
select(Predicates) ->
    lists:foldl(
        fun add_argument/2,
        #sparql_query{select = [<<"?s">>]},
        Predicates
    ).

%% @doc Construct a SPARQL query for a single subject with a set of predicates.
-spec select(binary(), [binary()]) -> sparql_query().
select(Uri, Predicates) ->
    Query = select(Predicates),
    and_where(<<"VALUES ?s {<", Uri/binary, ">}">>, Query).

%% @doc Eliminate duplicate solutions.
-spec distinct(sparql_query()) -> sparql_query().
distinct(Query) ->
    Query#sparql_query{distinct = true}.

%% @doc Resolve query arguments by replacing numerical placeholders with their
%%      LD predicate counterparts stored in Arguments.
-spec resolve_arguments(Bindings :: map(), sparql_query()) -> Bindings :: map().
resolve_arguments(Bindings, #sparql_query{arguments = Arguments}) ->
    maps:fold(
        fun(Key, Value, Acc) ->
            case maps:get(Key, Arguments, undefined) of
                undefined ->
                    Acc;
                ResolvedKey ->
                    Acc#{ResolvedKey => Value}
            end
        end,
        #{},
        Bindings
    ).

%% @doc Add a where clause to a query.
-spec and_where(binary(), sparql_query()) -> sparql_query().
and_where(Clause, #sparql_query{where = Clauses} = Query) ->
    Query#sparql_query{where = [Clause | Clauses]}.

%% @doc Add offset to query.
-spec offset(non_neg_integer(), sparql_query()) -> sparql_query().
offset(Offset, Query) when Offset >= 0 ->
    Query#sparql_query{offset = Offset}.

%% @doc Add limit to query.
-spec limit(pos_integer(), sparql_query()) -> sparql_query().
limit(Limit, Query) when Limit > 0 ->
    Query#sparql_query{limit = Limit}.

%% @doc Add a query argument.
-spec add_argument(binary(), sparql_query()) -> sparql_query().
add_argument(Property, #sparql_query{} = Query) ->
    #sparql_query{select = Select, arguments = Arguments, where = Where} = Query,
    Next = z_convert:to_binary(maps:size(Arguments) + 1),
    Argument = <<"?", Next/binary>>,
    Query#sparql_query{
        select = Select ++ [Argument],
        arguments = Arguments#{Next => Property},
        where = [<<"OPTIONAL {?s <", Property/binary, "> ?", Next/binary, "}">> | Where]
    }.

query_distinct(true) ->
    <<"DISTINCT ">>;
query_distinct(false) ->
    <<>>.

-module(session_simulation).
-export([run_sim/0, run_sim/3]).
-include("include/human.hrl").
-include_lib("eunit/include/eunit.hrl").
-define(RETRIES, 3).
-define(BABIES_PER_PERIOD, 500).
-define(GENE_SIZE, 100000).
-define(LIFETIME, 200).
-define(END_OF_PERIOD, (?LIFETIME * 10)).

make_gene(GeneSize) ->
    random:uniform(GeneSize).

birth(Count, People, GeneSize) ->
    Conflicted = 0,
    birth_acc(Count, People, GeneSize, Conflicted).

birth_acc(0, People, _GeneSize, Conflicted) ->
    {People, Conflicted};
birth_acc(Count, People, GeneSize, Conflicted) ->
    {Gene, Retries} = try_birth(GeneSize, People, ?RETRIES),
    birth_acc(Count - 1, [#human{gene=Gene}|People], GeneSize, Conflicted + Retries).

try_birth(GeneSize, People, MaxRetries) ->
    Retries = 0,
    try_birth_acc(GeneSize, People, MaxRetries, Retries).

try_birth_acc(GeneSize, People, MaxRetries, Retries) when Retries < MaxRetries ->
    Gene = make_gene(GeneSize),
    Conflicted = lists:filter(fun(#human{gene=G}) -> G =:= Gene end, People),
    case Conflicted of
        [] ->
            {Gene, Retries};
        _ ->
            try_birth_acc(GeneSize, People, MaxRetries, Retries + 1)
    end.

run_sim() ->
    run_sim(?BABIES_PER_PERIOD, ?GENE_SIZE, ?LIFETIME).

run_sim(BabiesPerPeriod, GeneSize, Lifetime) ->
    {Period, Conflicts, People} = {0, 0, []},
    turn(Period, Conflicts, People, BabiesPerPeriod, GeneSize, Lifetime).

turn(Period, Conflicts, _People, _BabiesPerPeriod, _GeneSize, _Lifetime) when Period =:= ?END_OF_PERIOD ->
    Conflicts;
turn(Period, Conflicts, People, BabiesPerPeriod, GeneSize, Lifetime) ->
    {People2, Conflicted} = birth(BabiesPerPeriod, People, GeneSize),
    People3 = lists:filtermap(fun(#human{lives_until=undefined} = Human) ->
                    {true, Human#human{lives_until=Period + Lifetime}};
                (Human) ->
                    {true, Human}
            end, People2),
    People4 = lists:filter(fun(#human{lives_until=L}) -> L < Period end, People3),
    case Period rem 100 of
        0 ->
            ?debugVal(Period),
            ?debugVal(Conflicted);
        _ ->
            ok
    end,
    turn(Period + 1, [Conflicted|Conflicts], People4, BabiesPerPeriod, GeneSize, Lifetime).

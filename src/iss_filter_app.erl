-module(iss_filter_app).
-export([handle/2, base_capabilities/0]).
-define(URL, "https://api.wheretheiss.at/v1/satellites/25544").

base_capabilities() ->
    em_filter:base_capabilities() ++
    [<<"iss">>, <<"station">>, <<"space">>, <<"espace">>, <<"spatiale">>,
     <<"astronaut">>, <<"astronaute">>, <<"orbit">>, <<"orbite">>, <<"satellite">>,
     <<"live">>, <<"nasa">>].

handle(Body, Memory) when is_binary(Body) -> {gen(extract_value(Body)), Memory};
handle(_Body, Memory) -> {[], Memory}.

gen("") -> [];
gen(_Q) ->
    case fetch_json(?URL) of
        {ok, #{<<"latitude">> := Lat, <<"longitude">> := Lon,
               <<"altitude">> := Alt, <<"velocity">> := Vel}} ->
            Resume = txt(["Now at ", fmt(Lat), ", ", fmt(Lon),
                          " - alt ", fmt(Alt), " km - ", fmt(Vel), " km/h"]),
            Url = txt(["https://www.google.com/maps?q=", fmt(Lat), ",", fmt(Lon)]),
            [#{<<"properties">> => #{
                <<"url">> => Url,
                <<"title">> => <<"International Space Station (live)">>,
                <<"resume">> => Resume,
                <<"source">> => <<"wheretheiss.at">>}}];
        _ -> []
    end.

%%==================== helpers ====================
extract_value(Body) ->
    try json:decode(Body) of
        Map when is_map(Map) ->
            binary_to_list(maps:get(<<"value">>, Map,
                           maps:get(<<"query">>, Map, <<"">>)));
        _ -> binary_to_list(Body)
    catch _:_ -> binary_to_list(Body) end.

fetch_json(Url) ->
    _ = application:ensure_all_started(inets),
    Headers = [{"User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"}],
    case httpc:request(get, {Url, Headers},
                       [{timeout, 15000}, {ssl, [{verify, verify_none}]}],
                       [{body_format, binary}]) of
        {ok, {{_, 200, _}, _, B}} ->
            case catch json:decode(B) of
                M when is_map(M) -> {ok, M};
                _ -> error
            end;
        _ -> error
    end.

txt(IoList) ->
    case unicode:characters_to_binary(IoList) of
        Bin when is_binary(Bin) -> Bin;
        _ -> <<>>
    end.

safe(B) when is_binary(B) -> B;
safe(L) when is_list(L) -> case unicode:characters_to_binary(L) of X when is_binary(X) -> X; _ -> <<>> end;
safe(_) -> <<>>.

fmt(N) when is_integer(N) -> integer_to_binary(N);
fmt(N) when is_float(N) -> float_to_binary(N, [{decimals, 1}]);
fmt(_) -> <<"?">>.

nth(L, I) when is_list(L), length(L) >= I -> lists:nth(I, L);
nth(_, _) -> undefined.

#!/usr/bin/env escript
%%! -pz ../rabbitmq-erlang-client ../rabbit_common ../jsx ../rabbitmq-erlang-client/ebin ../rabbit_common/ebin ../jsx/ebin

-include_lib("../rabbitmq-erlang-client/include/amqp_client.hrl").

main(Args) ->
  [Host, Port, Message] = Args,
  {ok, Connection} =
    amqp_connection:start(#amqp_params_network{host = Host,
                                               port = list_to_integer(Port),
                                               username = <<"guest">>,
                                               password = <<"guest">>,
                                               virtual_host = <<"/">>}),
  {ok, Channel} = amqp_connection:open_channel(Connection),

  Publish = #'basic.publish'{exchange = <<"incoming_orders">>,
                             routing_key = <<"warehouse">>},
  Msg = #amqp_msg{payload = jsx:encode([{<<"ordernum">>, crypto:rand_uniform(1, 100)},
                                        {<<"type">>, list_to_binary(Message)}]),
                  props = #'P_basic'{content_type = <<"application/json">>}},
  amqp_channel:cast(Channel, Publish, Msg),

  io:format("Sent avocado order message~n"),

  ok = amqp_channel:close(Channel),
  ok = amqp_connection:close(Connection),
  ok.


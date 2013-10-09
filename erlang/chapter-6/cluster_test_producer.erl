#!/usr/bin/env escript
%%! -pz ../rabbitmq-erlang-client ../rabbit_common ../jsx ../rabbitmq-erlang-client/ebin ../rabbit_common/ebin ../jsx/ebin

-include_lib("../rabbitmq-erlang-client/include/amqp_client.hrl").

main(Args) ->
  [Host, Port] = Args,
  {ok, Connection} =
    amqp_connection:start(#amqp_params_network{host = Host,
                                               port = list_to_integer(Port),
                                               username = <<"guest">>,
                                               password = <<"guest">>,
                                               virtual_host = <<"/">>}),
  {ok, Channel} = amqp_connection:open_channel(Connection),

  {Mega, Secs, _} = now(),
  Timestamp = Mega*1000000 + Secs,

  Msg = jsx:encode([
    {<<"content">>, <<"Cluster Test!">>},
    {<<"time">>, Timestamp}
  ]),

  Publish = #'basic.publish'{exchange = <<"">>, routing_key = <<"cluster_test">>},
  Message = #amqp_msg{payload = Msg,
                      props = #'P_basic'{content_type = <<"application/json">>,
                                         delivery_mode = 2}},

  amqp_channel:cast(Channel, Publish, Message),

  io:format("Sent cluster test message.~n"),

  ok = amqp_channel:close(Channel),
  ok = amqp_connection:close(Connection),
  ok.

#!/usr/bin/env escript
%%! -pz ../rabbitmq-erlang-client ../rabbit_common ../jsx ../rabbitmq-erlang-client/ebin ../rabbit_common/ebin ../jsx/ebin

-include("../rabbitmq-erlang-client/include/amqp_client.hrl").

main(Args) ->
  %% RoutingKey = "*.rate_limit" || "critical.*"
  [RoutingKey, Message] = Args,

  {ok, Connection} =
    amqp_connection:start(#amqp_params_network{host = "localhost",
                                               username = <<"alert_user">>,
                                               password = <<"alertme">>,
                                               virtual_host = <<"/">>}),
  {ok, Channel} = amqp_connection:open_channel(Connection),

  Publish = #'basic.publish'{exchange = <<"alerts">>,
                             routing_key = list_to_binary(RoutingKey)},
  
  Msg = #amqp_msg{payload = jsx:encode(list_to_binary(Message)),
                  props = #'P_basic'{content_type = <<"application/json">>}},
  amqp_channel:cast(Channel, Publish, Msg),

  io:format("Sent message ~p tagged with routing key '~p' to exchange '/'.~n",
    [Message, RoutingKey]),

  ok = amqp_channel:close(Channel),
  ok = amqp_connection:close(Connection),
  ok.

#!/usr/bin/env escript
%%! -pz ../rabbitmq-erlang-client ../rabbit_common ../rabbitmq-erlang-client/ebin ../rabbit_common/ebin

-include_lib("../rabbitmq-erlang-client/include/amqp_client.hrl").

main(Args) ->
  {ok, Connection} =
    amqp_connection:start(#amqp_params_network{host = "localhost",
                                               username = <<"guest">>,
                                               password = <<"guest">>}),
  {ok, Channel} = amqp_connection:open_channel(Connection),

  Exchange = #'exchange.declare'{exchange = <<"hello-exchange">>,
                                 type = <<"direct">>,
                                 passive = false,
                                 durable = true,
                                 auto_delete = false},
  #'exchange.declare_ok'{} = amqp_channel:call(Channel, Exchange),

  Publish = #'basic.publish'{exchange = <<"hello-exchange">>,
                             routing_key = <<"hola">>},

  [send(Channel, Publish, X) || X <- Args],

  ok = amqp_channel:close(Channel),
  ok = amqp_connection:close(Connection),
  ok.

send(Channel, Publish, X) ->
  amqp_channel:cast(Channel,
                    Publish, 
                    #amqp_msg{payload = list_to_binary(X)}),
  io:format(" [x] sent: ~p~n", [X]).

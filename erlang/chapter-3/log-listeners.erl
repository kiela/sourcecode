#!/usr/bin/env escript
%%! -pz ../rabbitmq-erlang-client ../rabbit_common ../rabbitmq-erlang-client/ebin ../rabbit_common/ebin

-include_lib("../rabbitmq-erlang-client/include/amqp_client.hrl").

main(_) ->
  {ok, Connection} =
    amqp_connection:start(#amqp_params_network{host = "localhost",
                                               username = <<"guest">>,
                                               password = <<"guest">>,
                                               virtual_host = <<"/">>}),
  {ok, Channel} = amqp_connection:open_channel(Connection),
  #'queue.declare_ok'{} =
    amqp_channel:call(Channel,
                      #'queue.declare'{queue = <<"">>}),

  #'queue.bind_ok'{} =
    amqp_channel:call(Channel,
                      #'queue.bind'{queue = <<"">>,
                                    exchange = <<"amq.rabbitmq.log">>,
                                    routing_key = <<"error">>}),
  #'queue.bind_ok'{} =
    amqp_channel:call(Channel,
                      #'queue.bind'{queue = <<"">>,
                                    exchange = <<"amq.rabbitmq.log">>,
                                    routing_key = <<"warning">>}),
  #'queue.bind_ok'{} =
    amqp_channel:call(Channel,
                      #'queue.bind'{queue = <<"">>,
                                    exchange = <<"amq.rabbitmq.log">>,
                                    routing_key = <<"info">>}),

  Subscribe = #'basic.consume'{queue = <<"">>},
  #'basic.consume_ok'{} = amqp_channel:call(Channel, Subscribe),

  loop(Channel),

  ok = amqp_channel:close(Channel),
  ok = amqp_connection:close(Connection),
  ok.

loop(Channel) ->
  receive
    #'basic.consume_ok'{} ->
      loop(Channel);
    #'basic.cancel_ok'{} ->
      ok;
    {#'basic.deliver'{delivery_tag = DeliveryTag,
                      routing_key = RoutingKey},
     Content} ->
      amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = DeliveryTag}),
      {_, _, Message} = Content,
      io:format(" [x] ~p: ~p~n", [list_to_atom(binary_to_list(RoutingKey)),
                                  binary_to_list(Message)]),
      loop(Channel)
  end.


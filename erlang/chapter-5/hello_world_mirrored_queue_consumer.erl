#!/usr/bin/env escript
%%! -pz ../rabbitmq-erlang-client ../rabbit_common ../rabbitmq-erlang-client/ebin ../rabbit_common/ebin

-include_lib("../rabbitmq-erlang-client/include/amqp_client.hrl").

main(_) ->
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

  QueueArgs = [{<<"x-ha-policy">>, longstr, <<"all">>}],
  Queue = #'queue.declare'{queue = <<"hello-queue">>,
                           arguments = QueueArgs},
  #'queue.declare_ok'{} = amqp_channel:call(Channel, Queue),

  Binding = #'queue.bind'{queue = <<"hello-queue">>,
                          exchange = <<"hello-exchange">>,
                          routing_key = <<"hola">>},
  #'queue.bind_ok'{} = amqp_channel:call(Channel, Binding),

  Subscribe = #'basic.consume'{queue = <<"hello-queue">>},
  #'basic.consume_ok'{consumer_tag = Tag} = amqp_channel:call(Channel, Subscribe),

  loop(Channel, Tag),

  ok = amqp_channel:close(Channel),
  ok = amqp_connection:close(Connection),
  ok.

loop(Channel, ConsumerTag) ->
  receive
    #'basic.consume_ok'{} ->
      loop(Channel, ConsumerTag);
    #'basic.cancel_ok'{} ->
      ok;
    {#'basic.deliver'{delivery_tag = DeliveryTag,
                      routing_key = <<"hola">>},
     Content} ->
      amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = DeliveryTag}),
      {_, _, Message} = Content,
      case Message of
        <<"quit">> ->
          amqp_channel:call(Channel, #'basic.cancel'{consumer_tag = ConsumerTag});
        Any ->
          io:format(" [x] received: ~p~n", [binary_to_list(Any)]),
          loop(Channel, ConsumerTag)
      end
  end.




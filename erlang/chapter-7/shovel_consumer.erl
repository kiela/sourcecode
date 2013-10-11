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

  Exchange = #'exchange.declare'{exchange = <<"incoming_orders">>,
                                 type = <<"direct">>,
                                 durable = true,
                                 auto_delete = false},
  #'exchange.declare_ok'{} = amqp_channel:call(Channel, Exchange),

  Queue = #'queue.declare'{queue = <<"warehouse_carpinteria">>,
                           durable = true,
                           auto_delete = false},
  #'queue.declare_ok'{} = amqp_channel:call(Channel, Queue),

  Binding = #'queue.bind'{queue = <<"warehouse_carpinteria">>,
                          exchange = <<"incoming_orders">>,
                          routing_key = <<"warehouse">>},
  #'queue.bind_ok'{} = amqp_channel:call(Channel, Binding),

  io:format("Ready for orders!~n"),

  Subscribe = #'basic.consume'{queue = <<"warehouse_carpinteria">>,
                               no_ack = false},
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
    {#'basic.deliver'{delivery_tag = Tag}, Content} ->
      {_, _, Message} = Content,
      [{<<"ordernum">>, OrderNum},
       {<<"type">>, Type}] = jsx:decode(Message),
      io:format(" [x] received: ~p for ~p~n", [OrderNum, binary_to_list(Type)]),
      amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = Tag}),
      loop(Channel)
  end.


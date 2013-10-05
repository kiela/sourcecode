#!/usr/bin/env escript
%%! -pz ../rabbitmq-erlang-client ../rabbit_common ../jsx ../rabbitmq-erlang-client/ebin ../rabbit_common/ebin ../jsx/ebin

-include("../rabbitmq-erlang-client/include/amqp_client.hrl").

main(_) ->
  {ok, Connection} = 
    amqp_connection:start(#amqp_params_network{host = "localhost",
                                               username = <<"rpc_user">>,
                                               password = <<"rpcme">>,
                                               virtual_host = <<"/">>}),
  {ok, Channel} = amqp_connection:open_channel(Connection),

  Exchange = #'exchange.declare'{exchange = <<"rpc">>,
                                 type = <<"direct">>,
                                 auto_delete = false},
  #'exchange.declare_ok'{} = amqp_channel:call(Channel, Exchange),

  Queue = #'queue.declare'{queue = <<"ping">>,
                           auto_delete = false},
  #'queue.declare_ok'{} = amqp_channel:call(Channel, Queue),

  Binding = #'queue.bind'{queue = <<"ping">>,
                          exchange = <<"rpc">>,
                          routing_key = <<"ping">>},
  #'queue.bind_ok'{} = amqp_channel:call(Channel, Binding),

  Subscribe = #'basic.consume'{queue = <<"ping">>,
                               consumer_tag = <<"ping">>},
  #'basic.consume_ok'{} = amqp_channel:call(Channel, Subscribe),

  io:format("Waiting for RPC calls...~n"),

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
      amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = Tag}),

      {_, Pbasic, Message} = Content,
      {'P_basic',
       _, _, _, _, _, _,
       RoutingKey,
       _, _, _, _, _, _, _} = Pbasic,

      [{<<"client_name">>, _ClientName},
        {<<"time">>, Time}] = jsx:decode(Message),
      io:format("Received API call...replaying...~n"),

      Publish =  #'basic.publish'{exchange = <<"">>,
                                  routing_key = RoutingKey},
      Payload = "Pong! " ++ integer_to_list(Time),
      Msg = #amqp_msg{payload = list_to_binary(Payload)},
      amqp_channel:cast(Channel, Publish, Msg),

      loop(Channel)
  end.


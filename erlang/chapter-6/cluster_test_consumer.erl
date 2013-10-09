#!/usr/bin/env escript
%%! -pz ../rabbitmq-erlang-client ../rabbit_common ../jsx ../rabbitmq-erlang-client/ebin ../rabbit_common/ebin ../jsx/ebin

-include_lib("../rabbitmq-erlang-client/include/amqp_client.hrl").

main(Args) ->
  [Host, Port] = Args,
  case amqp_connection:start(#amqp_params_network{host = Host,
                                                  port = list_to_integer(Port),
                                                  username = <<"guest">>,
                                                  password = <<"guest">>,
                                                  virtual_host = <<"/">>}) of
    {ok, Connection} ->
      erlang:monitor(process, Connection),
      {ok, Channel} = amqp_connection:open_channel(Connection),

      Exchange = #'exchange.declare'{exchange = <<"cluster_test">>,
                                    type = <<"direct">>,
                                    auto_delete = false},
      #'exchange.declare_ok'{} = amqp_channel:call(Channel, Exchange),

      Queue = #'queue.declare'{queue = <<"cluster_test">>,
                              auto_delete = false},
      #'queue.declare_ok'{} = amqp_channel:call(Channel, Queue),

      Binding = #'queue.bind'{queue = <<"cluster_test">>,
                              exchange = <<"cluster_test">>,
                              routing_key = <<"cluster_test">>},
      #'queue.bind_ok'{} = amqp_channel:call(Channel, Binding),

      io:format("Ready for testing!\n"),

      Subscribe = #'basic.consume'{queue = <<"cluster_test">>,
                                  no_ack = false,
                                  consumer_tag = <<"cluster_test">>},
      #'basic.consume_ok'{} = amqp_channel:call(Channel, Subscribe),

      loop(Channel, Args),

      ok = amqp_channel:close(Channel),
      ok = amqp_connection:close(Connection);
    {error, _} ->
      main(Args)
    end,
  ok.

loop(Channel, Args) ->
  receive
    #'basic.consume_ok'{} ->
      loop(Channel, Args);
    #'basic.cancel_ok'{} ->
      ok;
    {#'basic.deliver'{delivery_tag = DeliveryTag,
                      routing_key = <<"cluster_test">>},
     Content} ->
      amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = DeliveryTag}),
      {_, _, Message} = Content,
      [{<<"content">>, JsonContent},
       {<<"time">>, JsonTime}] = jsx:decode(Message),
      io:format(" [x] received: ~p/~p~n",
                [binary_to_list(JsonContent), JsonTime]),
      loop(Channel, Args);
    {'DOWN', _Ref, process, _Pid, Reason} ->
      io:format("~p~n", [Reason]),
      main(Args)
  end.



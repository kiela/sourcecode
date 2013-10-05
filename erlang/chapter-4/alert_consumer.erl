#!/usr/bin/env escript
%%! -pz ../rabbitmq-erlang-client ../rabbit_common ../jsx ../rabbitmq-erlang-client/ebin ../rabbit_common/ebin ../jsx/ebin

-include("../rabbitmq-erlang-client/include/amqp_client.hrl").

main(_) ->
  {ok, Connection} = 
    amqp_connection:start(#amqp_params_network{host = "localhost",
                                               username = <<"alert_user">>,
                                               password = <<"alertme">>,
                                               virtual_host = <<"/">>}),
  {ok, Channel} = amqp_connection:open_channel(Connection),

  Exchange = #'exchange.declare'{exchange = <<"alerts">>,
                                  type = <<"topic">>,
                                  auto_delete = false},
  #'exchange.declare_ok'{} = amqp_channel:call(Channel, Exchange),

  QueueCritical = #'queue.declare'{queue = <<"critical">>,
                                   auto_delete = false},
  #'queue.declare_ok'{} = amqp_channel:call(Channel, QueueCritical),

  BindingCritical = #'queue.bind'{queue = <<"critical">>,
                                  exchange = <<"alerts">>,
                                  routing_key = <<"critical.*">>},
  #'queue.bind_ok'{} = amqp_channel:call(Channel, BindingCritical),

  QueueRateLimit = #'queue.declare'{queue = <<"rate_limit">>,
                                   auto_delete = false},
  #'queue.declare_ok'{} = amqp_channel:call(Channel, QueueRateLimit),

  BindingRateLimit = #'queue.bind'{queue = <<"rate_limit">>,
                                   exchange = <<"alerts">>,
                                   routing_key = <<"*.rate_limit">>},
  #'queue.bind_ok'{} = amqp_channel:call(Channel, BindingRateLimit),

  SubscribeCritical = #'basic.consume'{queue = <<"critical">>,
                                       no_ack = false,
                                       consumer_tag = <<"critical">>},
  #'basic.consume_ok'{} = amqp_channel:call(Channel, SubscribeCritical),

  SubscribeRateLimit = #'basic.consume'{queue = <<"rate_limit">>,
                                       no_ack = false,
                                       consumer_tag = <<"rate_limit">>},
  #'basic.consume_ok'{} = amqp_channel:call(Channel, SubscribeRateLimit),

  io:format("Ready for alert!~n"),

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
    {#'basic.deliver'{delivery_tag = Tag,
                      routing_key = RoutingKey},
     Content} ->
      {_, _, Message} = Content,
      io:format(" [x] received ~p: ~p~n", [binary_to_list(RoutingKey),
                                           binary_to_list(jsx:decode(Message))]),
      amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = Tag}),
      loop(Channel)
  end.

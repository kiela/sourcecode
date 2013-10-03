#!/usr/bin/env escript
%%! -pz ../rabbitmq-erlang-client ../rabbit_common ../rabbitmq-erlang-client/ebin ../rabbit_common/ebin

-include_lib("../rabbitmq-erlang-client/include/amqp_client.hrl").

main(_) ->
  {ok, Connection} =
    amqp_connection:start(#amqp_params_network{host = "localhost",
                                               username = <<"guest">>,
                                               password = <<"guest">>}),
  {ok, Channel} = amqp_connection:open_channel(Connection),

  Exchange = #'exchange.declare'{exchange = <<"logs-exchange">>,
                                 type = <<"topic">>,
                                 passive = false,
                                 durable = true,
                                 auto_delete = false},
  #'exchange.declare_ok'{} = amqp_channel:call(Channel, Exchange),

  #'queue.declare_ok'{} =
    amqp_channel:call(Channel,
                      #'queue.declare'{queue = <<"msg-inbox-errors">>,
                                       passive = false,
                                       durable = true,
                                       exclusive = false,
                                       auto_delete = false}),
  #'queue.declare_ok'{} =
    amqp_channel:call(Channel,
                      #'queue.declare'{queue = <<"msg-inbox-logs">>,
                                       passive = false,
                                       durable = true,
                                       exclusive = false,
                                       auto_delete = false}),
  #'queue.declare_ok'{} =
    amqp_channel:call(Channel,
                      #'queue.declare'{queue = <<"all-logs">>,
                                       passive = false,
                                       durable = true,
                                       exclusive = false,
                                       auto_delete = false}),

  #'queue.bind_ok'{} =
    amqp_channel:call(Channel,
                      #'queue.bind'{queue = <<"msg-inbox-errors">>,
                                    exchange = <<"logs-exchange">>,
                                    routing_key = <<"error.msg-inbox">>}),

  #'queue.bind_ok'{} =
    amqp_channel:call(Channel,
                      #'queue.bind'{queue = <<"msg-inbox-logs">>,
                                    exchange = <<"logs-exchange">>,
                                    routing_key = <<"*.msg-inbox">>}),

  ok = amqp_channel:close(Channel),
  ok = amqp_connection:close(Connection),
  ok.



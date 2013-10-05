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

  {Mega, Secs, _} = now(),
  Timestamp = Mega*1000000 + Secs,
  Message = jsx:encode([{<<"client_name">>, <<"RPC Client 1.0">>},
                        {<<"time">>, Timestamp}]),

  Queue = #'queue.declare'{exclusive = true,
                           auto_delete = true},
  #'queue.declare_ok'{queue = ReplyTo} = amqp_channel:call(Channel, Queue),

  Publish =  #'basic.publish'{exchange = <<"rpc">>,
                              routing_key = <<"ping">>},
  amqp_channel:cast(Channel,
                    Publish,
                    #amqp_msg{payload = Message,
                              props = #'P_basic'{reply_to = ReplyTo}}),

  io:format("Sent 'ping' RPC call. Waiting for reply...~n"),

  Subscribe = #'basic.consume'{queue = ReplyTo},
  #'basic.consume_ok'{consumer_tag = ConsumerTag} =
    amqp_channel:call(Channel, Subscribe),

  loop(Channel),

  amqp_channel:call(Channel, #'basic.cancel'{consumer_tag = ConsumerTag}),

  ok = amqp_channel:close(Channel),
  ok = amqp_connection:close(Connection),
  ok.

loop(Channel) ->
  receive
    #'basic.consume_ok'{} ->
      loop(Channel);
    #'basic.cancel_ok'{} ->
      ok;
    {#'basic.deliver'{}, Content} ->
      {_, _, Message} = Content,
      io:format("RPC Reply --- ~p~n", [binary_to_list(Message)])
  end.


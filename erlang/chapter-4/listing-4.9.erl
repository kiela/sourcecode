#!/usr/bin/env escript
%%! -pz ../rabbitmq-erlang-client ../rabbit_common ../jsx ../rabbitmq-erlang-client/ebin ../rabbit_common/ebin ../jsx/ebin

-include("../rabbitmq-erlang-client/include/amqp_client.hrl").

main(_) ->
  {ok, Connection} = 
    amqp_connection:start(#amqp_params_network{host = "localhost",
                                               username = <<"guest">>,
                                               password = <<"guest">>,
                                               virtual_host = <<"/">>}),
  {ok, Channel} = amqp_connection:open_channel(Connection),

  Exchange = #'exchange.declare'{exchange = <<"upload-pictures">>,
                                 type = <<"fanout">>,
                                 durable = true},
  #'exchange.declare_ok'{} = amqp_channel:call(Channel, Exchange),

  Queue = #'queue.declare'{queue = <<"add-points">>,
                           durable = true},
  #'queue.declare_ok'{} = amqp_channel:call(Channel, Queue),

  Binding = #'queue.bind'{queue = <<"add-points">>,
                          exchange = <<"upload-pictures">>},
  #'queue.bind_ok'{} = amqp_channel:call(Channel, Binding),

  Subscribe = #'basic.consume'{queue = <<"add-points">>},
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

      case jsx:decode(Message) of
        <<"quit">> ->
          amqp_channel:cast(Channel, #'basic.cancel'{consumer_tag = Tag});
        [{<<"image_id">>, _ImageId},
         {<<"user_id">>, UserId},
         {<<"image_path">>, _ImagePath}] ->
          add_points_to_user(UserId),
          amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = Tag}),
          loop(Channel)
      end
  end.

add_points_to_user(UserId) ->
  io:format("Adding points to user: ~p~n", [UserId]).


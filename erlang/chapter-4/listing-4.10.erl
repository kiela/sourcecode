#!/usr/bin/env escript
%%! -pz ../rabbitmq-erlang-client ../rabbit_common ../jsx ../rabbitmq-erlang-client/ebin ../rabbit_common/ebin ../jsx/ebin

-include("../rabbitmq-erlang-client/include/amqp_client.hrl").

main(Args) ->
  [ImageId, UserId, ImagePath] = Args,
  {ok, Connection} = 
    amqp_connection:start(#amqp_params_network{host = "localhost",
                                               username = <<"guest">>,
                                               password = <<"guest">>,
                                               virtual_host = <<"/">>}),
  {ok, Channel} = amqp_connection:open_channel(Connection),

  Exchange = #'exchange.declare'{exchange = <<"upload-pictures">>,
                                 type = <<"fanout">>,
                                 passive = true,
                                 durable = true,
                                 auto_delete = false},
  #'exchange.declare_ok'{} = amqp_channel:call(Channel, Exchange),

  MetaData = jsx:encode([
    {<<"image_id">>, list_to_integer(ImageId)},
    {<<"user_id">>, list_to_integer(UserId)},
    {<<"image_path">>, list_to_binary(ImagePath)}
  ]),

  Publish =  #'basic.publish'{exchange = <<"upload-pictures">>},
  Message = #amqp_msg{payload = MetaData,
                      props = #'P_basic'{content_type = <<"application/json">>,
                                         delivery_mode = 2}},
  amqp_channel:cast(Channel, Publish, Message),

  ok = amqp_channel:close(Channel),
  ok = amqp_connection:close(Connection),
  ok.

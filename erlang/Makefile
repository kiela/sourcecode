all:
	wget https://github.com/rabbitmq/rabbitmq-codegen/archive/rabbitmq_v3_1_5.tar.gz
	tar -zxvf rabbitmq_v3_1_5.tar.gz
	mv rabbitmq-codegen-rabbitmq_v3_1_5 rabbitmq-codegen
	rm rabbitmq_v3_1_5.tar.gz
	wget https://github.com/rabbitmq/rabbitmq-server/archive/rabbitmq_v3_1_5.tar.gz
	tar -zxvf rabbitmq_v3_1_5.tar.gz
	mv rabbitmq-server-rabbitmq_v3_1_5 rabbitmq-server
	rm rabbitmq_v3_1_5.tar.gz
	wget https://github.com/rabbitmq/rabbitmq-erlang-client/archive/rabbitmq_v3_1_5.tar.gz
	tar -zxvf rabbitmq_v3_1_5.tar.gz
	mv rabbitmq-erlang-client-rabbitmq_v3_1_5 rabbitmq-erlang-client
	rm rabbitmq_v3_1_5.tar.gz
	cd rabbitmq-erlang-client && make
	rm -rf rabbitmq-codegen rabbitmq-server
	ln -s rabbitmq-erlang-client/deps/rabbit_common-0.0.0 rabbit_common

clean:
	rm rabbit_common
	rm -rf rabbitmq-erlang-client
	rm -f rabbitmq_v3_1_5.tar.gz

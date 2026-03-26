build:
	crystal build src/feeds.cr --no-codegen

test:
	crystal spec

fmt:
	crystal tool format src/

lint:
	./bin/ameba src/ spec/

clean:
	rm -rf bin/ lib/ .shards/

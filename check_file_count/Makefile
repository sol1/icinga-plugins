PROG=check_file_count
SRCS=${PROG}.go

build: ${PROG}

${PROG}: ${SRCS}
	go build -o $@ ${SRCS}

.PHONY: test clean
test: build
	mkdir -p $@
	@echo "test file 1" > $@/f1
	@echo "Testing warning threshold..."
	./${PROG} -w 1 -c 2 $@
	@echo "test file 2" > $@/f2
	@echo "Testing critical threshold..."
	./${PROG} -w 1 -c 2 $@

clean:
	rm -f ${PROG}
	rm -rf test

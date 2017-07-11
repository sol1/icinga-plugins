PROG=check_file_count
SRCS=${PROG}.go

${PROG}: ${SRCS}
	go build -o $@ ${SRCS}

.PHONY: test
test: build
	sh regress/test.sh

include ../Makefile

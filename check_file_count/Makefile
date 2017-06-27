PROG=check_file_count
SRCS=${PROG}.go

build: ${PROG}

${PROG}: ${SRCS}
	go build -o $@ ${SRCS}

.PHONY: test clean
test: build
	sh regress/test.sh

clean:
	rm -f ${PROG}

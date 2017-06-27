PROG=check_age
SRCS=${PROG}.go

PREFIX=/usr/local

build: ${PROG}

install: build
	install -m 555 -o root -g wheel ${PROG} ${PREFIX}/bin

${PROG}: ${SRCS}
	go build -o $@ ${SRCS}

.PHONY: test clean
test: build
	sh regress/test.sh

clean:
	rm -f ${PROG}
	rm -f regress/oldfile
	rm -f regress/newfile

PROG=check_age
SRCS=${PROG}.go

PREFIX=/usr/local

build: ${PROG}

install: build
	install -m 555 -o root -g wheel ${PROG} ${PREFIX}/bin

${PROG}: ${PROG}.go
	go build -o $@

.PHONY: clean
clean:
	rm -f ${PROG}

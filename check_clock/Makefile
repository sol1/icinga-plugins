PROG=check_clock
SRCS=${PROG}.go ntp.go

PREFIX=/usr/local

build: ${PROG}

install: build
	install -m 555 -o root -g wheel ${PROG} ${PREFIX}/bin

${PROG}: ${SRCS}
	go build -o $@

.PHONY: clean
clean:
	rm -f ${PROG}

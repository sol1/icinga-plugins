PROG= check_hwraid
SRCS= ${PROG}.go

all: ${PROG} README.md

.SUFFIXES: .go .1 .md
.go:
	go build -o $@ $>
.1.md:
	mandoc -T markdown $< > mandoc.out
	mv mandoc.out $@

README.md: ${PROG}.md
	cp ${PROG}.md $@

.PHONY: clean
clean:
	rm -f ${PROG} *.md

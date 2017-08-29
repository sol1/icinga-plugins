MANDIR= usr/local/share/man/man1
BINDIR= usr/lib/nagios/plugins
PREFIX?= ${.CURDIR}

SUBDIR= check_age check_ardomedf check_clock check_file_count check_hadr

# Include the below programs in the build.
PROGS=  check_age/check_age check_ardomedf/check_ardomedf \
	check_clock/check_clock \
	check_file_count/check_file_count check_hadr/check_hadr \
	check_oncall/check_oncall

build: ${PROGS}

${BINDIR} ${MANDIR}:
	mkdir -p $@

# Set generic rules to create a plugin 'binary' without a file extension for
# each language.
.SUFFIXES: .go .pl .sh
.go:
	@echo "==> ${@F}"
	go build -o $@ $<

.sh:
	@echo "==> ${@F}"
	rm -f $@
	@# Check shell for simple syntax errors
	sh -n $<
	cp $< $@

.pl:
	@echo "==> ${@F}"
	rm -f $@
	cp $< $@

.PHONY: clean install
clean:
	rm -f ${PROGS}
	rm -rf ${PREFIX}/${BINDIR}
	rm -rf ${PREFIX}/${MANDIR}
	rm -rf usr

install: build ${BINDIR} ${MANDIR}
	@echo "installing to ${PREFIX}/${BINDIR}"
	for p in ${PROGS}; do \
		install -m 555 $$p ${PREFIX}/${BINDIR}; \
	done

# Exceptions to the standard build recipes are included below.
include check_clock/Makefile

PREFIX?= build
MANDIR= ${PREFIX}/usr/local/share/man/man1
BINDIR= ${PREFIX}/usr/lib/nagios/plugins

SUBDIR= check_age check_ardomedf check_clock check_file_count check_hadr \
	check_oncall

build: ${PROG}

all:
	@for dir in ${SUBDIR}; do \
		echo "===> $$dir"; \
		make -C $$dir ${MAKE_FLAGS} build; \
	done

${SUBDIR}::
	@if test -d $@; then \
		echo "===> $@"; \
		exec make -C $@ ${MAKE_FLAGS} build; \
	fi

${PROG}:: ${SRCS}

# Set generic rules to create a plugin 'binary' without a file extension for
# each language.
.SUFFIXES: .go .pl .sh
.go:
	go build -o $@ $>

.sh:
	rm -f $@
	@# Check for simple shell syntax errors
	sh -n $<
	cp $< $@

.pl:
	rm -f $@
	cp $< $@

${BINDIR} ${MANDIR}:
	mkdir -p $@

# Create a zip archive for installation on windows.
${PREFIX}/icinga-plugins.zip: all ${PREFIX}/icinga-plugins/install.bat
	mkdir -p ${PREFIX}/icinga-plugins
	for entry in ${SUBDIR}; do \
		echo "===> $$entry"; \
		cp $$entry/$$entry ${PREFIX}/icinga-plugins; \
	done
	zip -r $@ ${PREFIX}/icinga-plugins

# Include windows install script in the distributed zip.
${PREFIX}/icinga-plugins/install.bat: script/install.bat
	cp script/install.bat $@

${PREFIX}/icinga-plugins: clean
	mkdir -p $@
	cp -R ${SUBDIR} $@
	cp Makefile $@

${PREFIX}/icinga-plugins.tar.gz: ${PREFIX}/icinga-plugins
	tar -f $@ -C build -cvz icinga-plugins

${PREFIX}/sol1-icingautil.deb: install
	fpm -s dir -t deb -s dir -C build -n sol1-icingautil .

${PREFIX}/sol1-icingautil.rpm: install
	fpm -s dir -t rpm -s dir -C build -n sol1-icingautil .

.PHONY: build all clean dist install package
clean:
	rm -f ${PROG} *.rpm *.deb *.tar.gz *.exe
	@if [ "${PROG}" = "" ]; then \
		for entry in ${SUBDIR}; do \
			echo "===> $$entry"; \
			make -C $$entry clean; \
		done; \
		rm -rf build; \
	fi

dist: ${PREFIX}/icinga-plugins.tar.gz ${PREFIX}/icinga-plugins.zip

install: all ${PREFIX} ${BINDIR} ${MANDIR}
	@echo "Installing plugins to ${BINDIR}"
	@echo "Installing man pages to ${MANDIR}"
	@# Install the binary. If there is an associated manpage, install it
	@# too.
	for p in ${SUBDIR}; do \
		install -m 555 $$p/$$p ${BINDIR}; \
		if [ -f $$p/$$p.1 ]; then \
		install -m 444 $$p/$$p.1 ${MANDIR}; \
		fi; \
	done

package: ${PREFIX}/sol1-icingautil.deb ${PREFIX}/sol1-icingautil.rpm

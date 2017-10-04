PREFIX?= build
MANDIR= ${PREFIX}/usr/local/share/man/man1
BINDIR= ${PREFIX}/usr/lib/nagios/plugins
# By default, do not compile binaries for windows. May set WINDOWS=true to
# cross compile linux/unix and windows.
WINDOWS?=

# Set plugins to be included in the main build. Keep this alphabetically sorted.
SUBDIR= check_age check_ardomedf check_clock check_file_count check_hadr \
	check_oncall check_winsock

build: ${PROG}

${PROG} ${EXE}:: ${SRCS}

# Rules to build a program when the current directory is not the program's
# directory, e.g. 'make check_oncall'
${SUBDIR}::
	@if test -d $@; then \
		echo "===> $@"; \
		exec make -C $@ ${MAKE_FLAGS} build; \
	fi

# Implicit rules.
.SUFFIXES: .exe .go .pl .sh
.go:
	go build -o $@ $>

.go.exe:
	GOOS=windows go build -o $@ $>

.sh:
	rm -f $@
	@# Check for simple shell syntax errors
	sh -n $<
	cp $< $@

.pl:
	rm -f $@
	cp $< $@

# Rules for recursive make. Builds all entries. If the WINDOWS env var is set,
# then build for both linux/unix and Windows platforms.
buildwin: ${PROG} ${EXE}
all:
	@for dir in ${SUBDIR}; do \
		echo "===> $$dir"; \
		if [ $$WINDOWS ]; then \
			make -C $$dir ${MAKE_FLAGS} buildwin; \
		else \
			make -C $$dir ${MAKE_FLAGS} build; \
		fi; \
	done

${BINDIR} ${MANDIR}:
	mkdir -p $@
# Rules for creating distributable files, either as source code (as a tarball)
# or pre-built packages (deb, rpm, zip).
dist/icinga-plugins: clean
	mkdir -p $@
	cp -R ${SUBDIR} $@
	cp Makefile $@

dist/icinga-plugins.tar.gz: dist/icinga-plugins
	tar -f $@ -C ${@D} -cvz icinga-plugins

dist/sol1-icingautil.deb: install
	fpm -s dir -t deb -s dir -C build -n sol1-icingautil .

dist/sol1-icingautil.rpm: install
	fpm -s dir -t rpm -s dir -C build -n sol1-icingautil .

# Not all plugins have windows exe files built, so check the exe exists before
# including.
dist/windows/sol1-icingautil.zip: dist/install.bat
	mkdir -p ${@D}
	for entry in ${SUBDIR}; do \
		echo "===> $$entry"; \
		if [ -f $$entry/$$entry.exe ]; then \
			echo "including $$entry.exe"; \
			cp $$entry/$$entry.exe ${@D}; \
		fi \
	done
	zip -r $@ ${@D}

.PHONY: build all clean install dist deb rpm zip
# Remove all build and distribution artefacts. Recursively clean each program
# directory if we're in the repository root.
clean:
	rm -f ${PROG} *.deb *.exe *.rpm *.tar.gz *.zip
	@if [ "${PROG}" = "" ]; then \
		for entry in ${SUBDIR}; do \
			echo "===> $$entry"; \
			make -C $$entry clean; \
		done; \
		rm -rf dist/icinga-plugins dist/*.tar.gz dist/windows; \
		rm -rf build; \
	fi

# By default, install build into dummy unix hierarchy under $PREFIX, which by
# default is ./build. Set $PREFIX to empty ("") to install to the local system.
install: all ${PREFIX} ${BINDIR} ${MANDIR}
	for p in ${SUBDIR}; do \
		install -m 555 $$p/$$p ${BINDIR}; \
		echo "installed $$p to ${BINDIR}"; \
		if [ -f $$p/$$p.1 ]; then \
			install -m 444 $$p/$$p.1 ${MANDIR}; \
			echo "installed $$p.1 to ${MANDIR}"; \
		fi; \
	done

# Handy aliases.
dist: dist/icinga-plugins.tar.gz
deb:  dist/sol1-icingautil.deb
rpm:  dist/sol1-icingautil.rpm
zip:  dist/windows/sol1-icingautil.zip

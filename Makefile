MANDIR=usr/local/share/man/man1
BINDIR=usr/lib/nagios/plugins
PREFIX=../pkg
PKG=sol1-icingautil

SUBDIR= check_age check_ardomedf check_clock check_file_count

# Make the default target for each utility.
build:
	for d in ${SUBDIR}; do \
		$(MAKE) -C $$d; \
	done

# Create directory hierarchy expected by installation and packaging routines.
pkg:
	mkdir -p $@

pkg/${BINDIR} pkg/${MANDIR}:
	mkdir -p $@

pkg/windows:
	mkdir -p $@

# Linux/unix binaries are put into their installation directory on mirrored on
# the local filesystem, to be packaged into rpm and deb files by fpm(1).
# Windows exe files are installed into a flat directory and compressed into a
# zip archive.
ifeq (GOOS, windows)
install:
	@install -m 555 ${PROG}.exe ${PREFIX}/windows
else
install: 
	@install -m 555 ${PROG} ${PREFIX}/${BINDIR}
	# Install manpages, if any.
	@if test -f ${PROG}.1; then \
		install -m 444 ${PROG}.1 ${PREFIX}/${MANDIR}; \
	fi
endif

${PKG}.deb: pkg/${BINDIR} pkg/${MANDIR} build
	@for s in ${SUBDIR}; do \
		echo "installing $$s..."; \
		$(MAKE) -C $$s install; \
	done
	# Manually remove old package before rebuilding;
	# fpm will not overwrite packages.
	@rm $@
	fpm -n ${PKG} -p $@ -s dir -t deb -C pkg

${PKG}.rpm: pkg/${BINDIR} pkg/${MANDIR} build
	@for s in ${SUBDIR}; do \
		echo "installing $$s..."; \
		$(MAKE) -C $$s install; \
	done
	@# Manually remove old package before rebuilding;
	@# fpm will not overwrite packages.
	@rm $@
	fpm -n ${PKG} -p $@ -s dir -t rpm -C pkg

${PKG}.zip: build

# Remove temporary and built files from the repo root and each utility
# directory.
.PHONY: clean cleanall
clean: cleanall
	rm -rf pkg
	rm -f *.deb
	rm -f *.rpm
	rm -f ${PROG}
	rm -f ${PROG}.exe

cleanall:
	@for d in ${SUBDIR}; do \
		echo "Removing build of $$d..."; \
		rm -f $$d/$$d; \
		rm -f $$d/$$d.exe; \
	done

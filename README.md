# Sol1 Icinga plugins

An internal repository of Icinga plugins commonly installed as `/usr/lib/nagios/plugins/sol1` by Ansible.

## Plugins as submodules

Some plugins are maintained in their own git repositories and included in this one using git submodules for unified deployment using Ansible. For example, [icinga-check-rabbitmq](https://github.com/sol1/icinga-check-rabbitmq) is installed as `/usr/lib/nagios/plugins/sol1/icinga-check-rabbitmq`.

If you have cloned this repo, run the following commands to populate those submodule directories locally:

```
git submodule init
git submodule update
```

If you then make changes locally, here's how to publish them:

* Checkout master within the plugin subdir (e.g. `icinga-check-rabbitmq`)
* git add, commit and push from inside the subdir
* cd back to the root dir of this repo then add, commit and push the changes. This updates the pointer in the main git repo to the correct ref in the submodule repo.

## TODO

 * As we write more plugins, include them as a submodule only, so this repo becomes more like a "meta" or dependency package.

## Build sol1-icingautils
To build plugin executables, run make(1):

```
$ make
```

Packages for debian- and redhat-based distributions may be built with make(1).
Specify the name of the package as the first argument of make(1) to generate the
package:

```
$ make sol1-icingautils.deb
$ make sol1-icingautils.rpm
```

To remove build artefacts, specify the clean target:

```
$ make clean
```

### Building each plugin
Each program consists of a subdirectory and its own Makefile. The following is a
simple but functional Makefile for a monitoring plugin "check-stuff":

```
PROG=check-stuff
SRCS=check-stuff.sh

# check-stuff depends on check-stuff.sh
# if check-stuff.sh is newer than check-stuff, then the build is run.
${PROG}: ${SRCS}

# Include the root Makefile for common routines such as 'install' and 'build'
include ../Makefile
```

When (and only when!) "check-stuff" has been documented and tested, it can be
included in the build to be released. This means simply adding the "check-stuff"
subdirectory to the list of directories to call make(1) in.

```
MANDIR=usr/local/share/man/man1
BINDIR=usr/lib/nagios/plugins
PREFIX=../pkg
PKG=sol1-icingautil

SUBDIR= check_age check_ardomedf check_clock check_file_count check-stuff \
    check_isilon check_something check_somethingelse \
    check_this check_that check_everything
```

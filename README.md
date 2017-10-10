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

## Building
To build plugins from source, run make(1) without any arguments:

```
$ make
```

To remove build artefacts (that is, to get a clean slate), run make with the
argument 'clean':

```
$ make clean
```

To build for both Windows and host operating system, set the WINDOWS environment
variable to 'true':

```
$ WINDOWS=true make
```

To build pre-compiled operating system packages, run make with the type of
package as the arguemnt. Currently the supported options are 'dist' (tar.gz),
'deb', 'rpm' and 'zip'.

```
$ make deb rpm
```

## Development
Each plugin source is found in its own subdirectory, with its own Makefile. The
per-plugin Makefile defines just the name of the program and the source files
from which it is built. A simple but functional Makefile for the plugin
'check_stuff' follows:

```
PROG=check-stuff
SRCS=check-stuff.sh

# Include the main Makefile to include instructions on how to build and test
# the program.
include ../Makefile
```

make(1) may be run from within the subdirectory to build/test just the single
plugin, without needing to build the entire collection:

```
$ cd check_stuff
$ make # will only build check_stuff.
```

Alternatively from the repository root, to build 'check_stuff' and
'check_age':

```
$ make check_stuff check_age
```

When (and only when!) "check_stuff" has been documented and tested, it can be
included in the main build to be released. In the repository root Makefile,
all subdirectories listed in the variable 'SUBDIR' are built.

```
SUBDIR= check_age check_ardomedf check_clock \
    check_file_count check_isilon check_stuff check_stuff 
```

Having plugins defined explicitly in the root Makefile means we are able to
continuously develop plugins in version control without releasing unfinished
plugins in a package.

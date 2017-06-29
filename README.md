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

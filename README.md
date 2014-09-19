nutcracker Cookbook
===================

This cookbook is designed to install nutcracker and configure it.
Configuration can be done using one of three methods:

1. Based on information obtained from data bags
2. Using the LWRP-provided DSL from within an application cookbook
3. Searching for nodes with a particular role to use as member servers

Which method is used depends on the implementation details of the
individual infrastructure.

Requirements
------------

None, other than a platform that is supported by nutcracker itself.

See https://github.com/twitter/twemproxy for a list.

Attributes
----------

The attributes for this cookbook are organized in a way such that
general defaults come first, then any platform-specific overrides,
followed by any switches used to activate functionality present in the
default recipe. Most of the attributes themselves come from what is
available to `nutcracker` as command-line options.

* `nutcracker[:mbuf_size]` - size of mbuf chunk in bytes, see the
  [recommendation document](https://github.com/twitter/twemproxy/blob/master/notes/recommendation.md)
  for a discussion of how to set this
* `nutcracker[:verbosity]` - log level (can be run in production)
* `nutcracker[:output]` - path to log file
* `nutcracker[:stats_port]` - stats monitoring port
* `nutcracker[:stats_addr]` - stats monitoring ip
* `nutcracker[:stats_interval]` - stats aggregation interval in msec
* `nutcracker[:pid_file]` - path to pid file

* `nutcracker[:package_name]` - the name of the package to install.
* `nutcracker[:package_url]` - in case there's no package available
  upstream, this URL can point to an independent package
* `nutcracker[:package_checksum]` - the SHA256 checksum of the
  independently-provided package
* `nutcracker[:conf_file]` - the path to the YAML configuration file,
  used to specify the server pools and member servers.
* `nutcracker[:conf_dir]` - the path to a directory used to store
  files that get integrated into the configuration file

* `nutcracker[:service_name]` - the name of the service registered
  with the system
* `nutcracker[:rc_register]` - the command needed to register the
  service with the service management subsystem (if any)
* `nutcracker[:rc_file]` - the path to the run control file
* `nutcracker[:rc_mode]` - the filemode of the run control file

* `nutcracker[:data_bag]` - the name of the data bag used to configure
  the server pool(s)
* `nutcracker[:role_name]` - the name of the role that member server
  nodes carry
* `nutcracker[:role_interface]` - the interface of the member server
  whose IP address should be used in the configuration of the pool
* `nutcracker[:default_settings]` - a hash of valid
  [configuration keys](https://github.com/twitter/twemproxy#configuration)
  for `nutcracker` and their values (see the attribute file for the
  cookbook's current list)

Usage
-----

Use this cookbook by including the default recipe in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[nutcracker]"
  ]
}
```

This will install the `nutcracker` package.  In order to configure the
software, you may choose one of three methods.  Once `nutcracker` has
been configured, it will start and be kept running.

### Via Data Bags

Choose to configure the server pool(s) by setting the
`nutcracker[:data_bag]` attribute to the name of the data bag
containing items with the following structure:

```json
{
  "id": "<unique-name>",
  "enabled_on": [ "<node1>", "<node2>", ... ],
  "pools": [
    {
      "name": "<pool-name>",
      "listen": "<ip>:<port>",
      "hash": "<hash-function>",
      "hash_tag": "<two-character-string>",
      "distribution": "<key-distribution-mode>",
      "timeout": "<number-of-msec-for-server>",
      "backlog": "<TCP-backlog>",
      "preconnect": <boolean>,
      "redis": <boolean>,
      "server_connections": "<number-of-conn-to-server>",
      "auto_eject_hosts": <boolean>,
      "server_retry_timeout": "<number-of-msec-to-retry-ejected-server>",
      "server_failure_limit": "<number-of-fails-to-eject>",
      "servers": [
        "<ip:port:weight-tuple>",
	"<ip:port:weight-tuple> <name>"
      ]
    }
  ]
}
```

The only required fields are `id`, `pools`, `name`, and `servers`.

`listen` will default to `0.0.0.0:6379` if `redis` is `true`,
`0.0.0.0:11211` otherwise.  This means that if there is more than one
object under `pools`, `listen` is _required_ for all but the first.

`enabled_on` is an array of Chef node names where this configuration
should be applied.  If empty, the configuration won't be used.  If
this field is missing, the configuration will be used on every node
that has the `nutcracker` recipe in its run list and
`nutcracker[:data_bag]` set to a data bag containing this item.

The other fields are best described on the
[nutcracker github page](https://github.com/twitter/twemproxy).

### Via LWRP

Similar in form to the contents of the `pools` object of the data bag,
the LWRP provides a DSL to configure `nutcracker`.  The
`nutcracker_pool` resource is to be used in a recipe as follows:

```ruby
nutcracker_pool "omega" do
  listen '/tmp/gamma'
  hash 'hsieh'
  distribution 'ketama'
  auto_eject_hosts false
  servers [ '127.0.0.1:11214:100000', '127.0.0.1:11215:1' ]
end
```

This will configure the "omega" `pool`, as shown in the example at
https://github.com/twitter/twemproxy.

All other configuration keys are available to use as a method
within the `nutcracker_pool` block.

The `nutcracker_pool` resource prepares a configuration object on the
node, which is then used by the `file` resource within the default
recipe.  It is this `file` resource that actually writes out the
configuration file, so it is possible to configure multiple pools in
separate recipes.

In order to use the `nutcracker_pool` resource from an application
cookbook, you will need to add the following to the `metadata.rb` file
of your application cookbook:

    depends 'nutcracker'

and use 

    include_recipe 'nutcracker'

after the place in the recipe where the `nutcracker_pool` resource is
used, or ensure that `recipe[nutcracker]` comes after your application
cookbook in the node's runlist.

### Via Roles

This is the least flexible of the three methods of configuring
`nutcracker`, due to the fact that only one pool may be configured.
Depending on the infrastructure, it may suffice.  The
`nutcracker[:role_name]` is set to the name of a role carried by the
nodes which make up this server pool.  This attribute may itself be
set via a role:

```ruby
name "nutcracker-redis"
description "Sets up a node to run nutcracker, searching for servers with the role 'redis' to add to its server pool."
default_attributes(
  :nutcracker => {
    :default_settings => {
      "redis" => true
    },
    "role_name" => 'redis'
  }
)
run_list(
  "recipe[nutcracker]"
)
```

The `nutcracker[:default_settings][:redis]` attribute is set to `true`
so that the `listen` key will be set to `0.0.0.0:6379` and the `redis`
key will also be `true`.

Any of the other `nutcracker[:default_settings]` may also be set, in
order to control the configuration of this role-based pool.

Contributing
------------

Anyone is welcome to submit pull requests to make changes/corrections.
If the PR is to add a compile recipe, it will be rejected.  Software
should be installed via packages - any variations should be taken into
account within the build process.  If your OS doesn't have a package
for `nutcracker` or `twemproxy`, build one yourself and make use of
the `nutcracker[:package_url]` and `nutcracker[:package_checksum]`
attributes or bug the maintainers to build one.

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------

Author:: Dimitri Aivaliotis <dna@everyware.ch>

Copyright 2014, EveryWare AG

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

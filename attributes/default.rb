#
# Cookbook Name:: nutcracker
# Attributes:: default
# Author:: Dimitri Aivaliotis <dna@everyware.ch>
#
# Copyright 2014, EveryWare AG
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default[:nutcracker][:mbuf_size] = '16384'
default[:nutcracker][:verbosity] = '5'
default[:nutcracker][:output] = 'stderr'
default[:nutcracker][:stats_port] = '22222'
default[:nutcracker][:stats_addr] = '0.0.0.0'
default[:nutcracker][:stats_interval] = '30000'
default[:nutcracker][:pid_file] = '/var/run/nutcracker.pid'

default[:nutcracker][:package_name] = 'nutcracker'
default[:nutcracker][:package_url] = nil
default[:nutcracker][:package_checksum] = nil
default[:nutcracker][:conf_file] = '/etc/nutcracker/nutcracker.yml'
default[:nutcracker][:conf_dir] = '/etc/nutcracker/.conf.d'

default[:nutcracker][:service_name] = 'nutcracker'
default[:nutcracker][:rc_register] = 'echo "NOT DEFINED FOR THIS PLATFORM"'
default[:nutcracker][:rc_file] = '/etc/init.d/nutcracker'
default[:nutcracker][:rc_mode] = '0755'

case platform
when "freebsd"
  default[:nutcracker][:conf_file] = '/usr/local/etc/nutcracker.yml'
  default[:nutcracker][:conf_dir] = '/usr/local/etc/.nutcracker.d'
  default[:nutcracker][:rc_file] = '/usr/local/etc/rc.d/nutcracker'
when "smartos"
  default[:nutcracker][:conf_file] = '/opt/local/etc/nutcracker.yml'
  default[:nutcracker][:conf_dir] = '/opt/local/etc/.nutcracker.d'
  default[:nutcracker][:rc_register] = 'svccfg import /opt/local/lib/svc/manifest/nutcracker.xml'
  default[:nutcracker][:rc_file] = '/opt/local/lib/svc/manifest/nutcracker.xml'
  default[:nutcracker][:rc_mode] = '0644'
end

default[:nutcracker][:data_bag] = nil
default[:nutcracker][:role_name] = nil
default[:nutcracker][:role_interface] = 'ipaddress'

default[:nutcracker][:default_settings] = {
  "listen" => '0.0.0.0:11211',
  "hash" => 'one_at_a_time',
  "hash_tag" => nil,
  "distribution" => 'random',
  "timeout" => '400',
  "backlog" => '512',
  "preconnect" => false,
  "redis" => false,
  "server_connections" => '1',
  "auto_eject_hosts" => true,
  "server_retry_timeout" => '30000',
  "server_failure_limit" => '3'
}

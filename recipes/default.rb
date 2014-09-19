#
# Cookbook Name:: nutcracker
# Recipe:: default
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
begin
  package node[:nutcracker][:package_name]
rescue Chef::Exceptions::Package
  cache_path = ::File.join(Chef::Config[:file_cache_path],  ::File::basename(node[:nutcracker][:package_url]))

  remote_file "download nutcracker" do
    path cache_path
    source node[:nutcracker][:package_url]
    checksum node[:nutcracker][:package_checksum]
    action :create_if_missing
  end

  package node[:nutcracker][:package_name] do
    source cache_path
    action :nothing
    subscribes :install, resources(:remote_file => "download nutcracker"), :immediately
  end
end

directory node[:nutcracker][:conf_dir]

unless node[:nutcracker][:data_bag].nil?
  search(node[:nutcracker][:data_bag], "*:*").each do |item|
    if item.enabled_on.nil? or item.enabled_on.include?(node.name)
      item.pools.each do |pool|
        if pool.listen
          listen = pool.listen
        elsif pool.redis
          listen = '0.0.0.0:6379'
        else
          listen = '0.0.0.0:11211'
        end
        nutcracker_pool pool.name do
          listen listen
          hash pool.hash if pool.hash
          hash_tag pool.hash_tag if pool.hash_tag
          distribution pool.distribution if pool.distribution
          timeout pool.timeout if pool.timeout
          backlog pool.backlog if pool.backlog
          preconnect pool.preconnect if pool.preconnect
          redis pool.redis if pool.redis
          server_connections pool.server_connections if pool.server_connections
          auto_eject_hosts pool.auto_eject_hosts if pool.auto_eject_hosts
          server_retry_timeout pool.server_retry_timeout if pool.server_retry_timeout
          server_failure_limit pool.server_failure_limit if pool.server_failure_limit
          servers pool.servers
        end
      end
    end
  end
end

unless node[:nutcracker][:role_name].nil?
  port = node[:nutcracker][:default_settings][:redis] ? "6379" : "11211"
  servers = []
  search(:node, "role:#{node[:nutcracker][:role_name]} AND chef_environment:#{node.chef_environment}").each do |server|
    interface = server.eval(node[:nutcracker][:role_interface])
    ipaddress = interface.class == Array ? interface.first : interface
    servers << "#{ipaddress}:#{port}:1"
  end
  if node[:nutcracker][:default_settings][:listen] != node.default[:nutcracker][:default_settings][:listen]
    listen = node[:nutcracker][:default_settings][:listen]
  elsif node[:nutcracker][:default_settings][:redis]
    listen = '0.0.0.0:6379'
  else
    listen = '0.0.0.0:11211'
  end
  nutcracker_pool "#{node[:nutcracker][:role_name]}_role" do
    listen listen
    hash node[:nutcracker][:default_settings][:hash]
    hash_tag node[:nutcracker][:default_settings][:hash_tag]
    distribution node[:nutcracker][:default_settings][:distribution]
    timeout node[:nutcracker][:default_settings][:timeout]
    backlog node[:nutcracker][:default_settings][:backlog]
    preconnect node[:nutcracker][:default_settings][:preconnect]
    redis node[:nutcracker][:default_settings][:redis]
    server_connections node[:nutcracker][:default_settings][:server_connections]
    auto_eject_hosts node[:nutcracker][:default_settings][:auto_eject_hosts]
    server_retry_timeout node[:nutcracker][:default_settings][:server_retry_timeout]
    server_failure_limit node[:nutcracker][:default_settings][:server_failure_limit]
    servers servers
  end
end

conf = ''
::Dir.glob(::File.join(node[:nutcracker][:conf_dir],'*')).each do |file|
  File.readlines(file).each do |line|
    # nc_conf.c:864 conf: document start token (5) is disallowed
    next if line == "---\n"
    conf << line
  end
  conf << "\n"
end

file node[:nutcracker][:conf_file] do
  content conf
end

execute "register nutcracker rc" do
  command node[:nutcracker][:rc_register]
  action :nothing
end

args=""
args+=" -m #{node[:nutcracker][:mbuf_size]}" if node[:nutcracker][:mbuf_size] != node.default[:nutcracker][:mbuf_size]
args+=" -v #{node[:nutcracker][:verbosity]}" if node[:nutcracker][:verbosity] != node.default[:nutcracker][:verbosity]
args+=" -o #{node[:nutcracker][:output]}" if node[:nutcracker][:output] != node.default[:nutcracker][:output]
args+=" -s #{node[:nutcracker][:stats_port]}" if node[:nutcracker][:stats_port] != node.default[:nutcracker][:stats_port]
args+=" -a #{node[:nutcracker][:stats_addr]}" if node[:nutcracker][:stats_addr] != node.default[:nutcracker][:stats_addr]
args+=" -i #{node[:nutcracker][:stats_interval]}" if node[:nutcracker][:stats_interval] != node.default[:nutcracker][:stats_interval]
args+=" -p #{node[:nutcracker][:pid_file]}" if node[:nutcracker][:pid_file] != node.default[:nutcracker][:pid_file]

template node[:nutcracker][:rc_file] do
  source 'rc.erb'
  mode node[:nutcracker][:rc_mode]
  variables(:command_args => args)
  notifies :run, resources(:execute => "register nutcracker rc"), :immediately
end

service node[:nutcracker][:service_name] do
  action [ :enable, :start ]
  subscribes :restart, resources(:file => node[:nutcracker][:conf_file])
end

#
# Cookbook Name:: nutcracker
# Resource:: pool
# Author::  Dimitri Aivaliotis (<dna@everyware.ch>)
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
actions :create, :delete

attribute :name, :kind_of => String, :name_attribute => true
attribute :listen, :kind_of => String, :default => '0.0.0.0:11211'
attribute :hash, :kind_of => String, :default => 'one_at_a_time'
attribute :hash_tag, :kind_of => String
attribute :distribution, :kind_of => String, :default => 'random'
attribute :timeout, :kind_of => String, :default => '400'
attribute :backlog, :kind_of => String, :default => '512'
attribute :preconnect, :kind_of => [String, TrueClass, FalseClass], :default => false
attribute :redis, :kind_of => [String, TrueClass, FalseClass], :default => false
attribute :server_connections, :kind_of => String, :default => '1'
attribute :auto_eject_hosts, :kind_of => [String, TrueClass, FalseClass], :default => true
attribute :server_retry_timeout, :kind_of => String, :default => '30000'
attribute :server_failure_limit, :kind_of => String, :default => '3'
attribute :servers, :kind_of => Array, :default => []

default_action :create

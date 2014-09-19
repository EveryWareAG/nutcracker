#
# Cookbook Name:: nutcracker
# Provider:: pool
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
require 'yaml/store'

def whyrun_supported?
  true
end

action :create do
  file = ::File.join(node[:nutcracker][:conf_dir],new_resource.name)
  converge_by("create YAML::Store #{file}") do
    store = YAML::Store.new(file)
    store.transaction do
      store[new_resource.name] = { }
      new_resource.methods.each do |var|
        if var =~ /_set_or_return/
          key = var.to_s.split(/_set_or_return_/).last
          value = eval("new_resource.#{key}")
          next if key.to_s == 'name' or value == nil
          store[new_resource.name].store(key,value)
        end
      end
    end
  end
  new_resource.updated_by_last_action(true)
end

action :delete do
  file = ::File.join(node[:nutcracker][:conf_dir],new_resource.name)
  if ::File.exists?(file)
    converge_by("delete YAML::Store #{file}") do
      file file do
        action :delete
      end
      new_resource.updated_by_last_action(true)
    end
  end
end

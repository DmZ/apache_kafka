# encoding: UTF-8
# Cookbook Name:: apache_kafka
# Recipe:: configure
#

[
  node["apache_kafka"]["config_dir"],
  node["apache_kafka"]["bin_dir"],
  node["apache_kafka"]["log_dir"],
].each do |dir|
  directory dir do
    recursive true
    owner node["apache_kafka"]["user"]
  end
end

%w{ kafka-server-start.sh kafka-run-class.sh kafka-topics.sh }.each do |bin|
  template ::File.join(node["apache_kafka"]["bin_dir"], bin) do
    source "bin/#{bin}.erb"
    owner "kafka"
    action :create
    mode "0755"
    variables(
      :config_dir => node["apache_kafka"]["config_dir"],
      :bin_dir => node["apache_kafka"]["bin_dir"],
      :log_dir => node["apache_kafka"]["log_dir"]
    )
    notifies :restart, "service[kafka]", :delayed
  end
end

array = node["apache_kafka"]["broker.id"] 
hash = Hash[array.map.with_index.to_a]
broker_id = hash[node["ipaddress"]]

template ::File.join(node["apache_kafka"]["config_dir"],
                     node["apache_kafka"]["conf"]["server"]["file"]) do
  source "properties/server.properties.erb"
  owner "kafka"
  action :create
  mode "0644"
  variables(
    :broker_id => broker_id,
    :port => node["apache_kafka"]["port"],
    :zookeeper_connect => node["apache_kafka"]["zookeeper.connect"],
    :entries => node["apache_kafka"]["conf"]["server"]["entries"]
  )
  notifies :restart, "service[kafka]", :delayed
end

template ::File.join(node["apache_kafka"]["config_dir"],
                     node["apache_kafka"]["conf"]["log4j"]["file"]) do
  source "properties/log4j.properties.erb"
  owner "kafka"
  action :create
  mode "0644"
  variables(
    :log_dir => node["apache_kafka"]["log_dir"],
    :entries => node["apache_kafka"]["conf"]["log4j"]["entries"]
  )
  notifies :restart, "service[kafka]", :delayed
end

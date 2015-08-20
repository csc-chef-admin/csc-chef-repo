#
# Cookbook Name:: win_hostconfig
# Recipe:: default
# Notes: For any issue found in this recipe, contact laguja2@csc.com or jgarcia58@csc.com
# Description: This recipe includes actions to configure host settings on a target node based on its node attributes
#
# Copyright 2015, CSC-FSG-AWS "To be used internally"

# Install Dependency
::Chef::Recipe.send(:include, Windows::Helper)

node_hostname = node['set_host']
node_ipaddress = node['primary_ip']
node_ipaddress2 = node['secondary_ip']
node_prefix = node['prefix']
node_gateway = node['gateway']
node_dnsservers = node['dns_servers']
node_interface = node['interface_label']

# Set hostname and IP information
powershell 'set-hostname' do
	code <<-EOS
		$hostname = Get-WmiObject Win32_ComputerSystem
		$hostname.Rename("#{node_hostname}")

		Get-NetAdapter -Name "#{node_interface}" | Set-NetIPInterface -Dhcp Disabled
		Get-NetAdapter -Name "#{node_interface}" | New-NetIPAddress -IPAddress "#{node_ipaddress}" -PrefixLength "#{node_prefix}" -DefaultGateway "#{node_gateway}"
		Set-DnsClientServerAddress -InterfaceAlias "#{node_interface}" -ServerAddresses "#{node_dnsservers}"
	EOS
end

if node.attribute?('secondary_ip')
	powershell 'set-secondary-ip' do
		code <<-EOS
			New-NetIPAddress -InterfaceAlias "#{node_interface}" -IPAddress "#{node_ipaddress2}" -PrefixLength "#{node_prefix}"
		EOS
	end
end
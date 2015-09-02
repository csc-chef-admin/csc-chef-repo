#
# Cookbook Name:: win_registry
# Recipe:: default
# Notes: For any issue found in this recipe, contact laguja2@csc.com or jgarcia58@csc.com
# Description: This recipe includes actions to set or modify registry values on target nodes
#
# Copyright 2015, CSC-FSG-AWS "To be used internally"

# Set Primary DNS Suffix on target Windows node
windows_registry 'HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters' do
	values 'NV Domain' => 'csc-fsg-aws.com'
	type :string
end

# Disable IE Enhanced Security
windows_registry 'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' do
	values 'IsInstalled' => 0
	type :dword
end

windows_registry 'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' do
	values 'IsInstalled' => 0
	type :dword
end

windows_registry 'HKCU\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' do
	values 'IsInstalled' => 0
	type :dword
end

windows_registry 'HKCU\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' do
	values 'IsInstalled' => 0
	type :dword
end

# Disable UAC
windows_registry 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' do
	values 'ConsentPromptBehaviorAdmin' => 0
	type :dword
end

# Disable Local Policy subcategory auditing
windows_registry 'HKLM\SYSTEM\CurrentControlSet\Control\LSA' do
	values 'SCENoApplyLegacyAuditPolicy' => 0
	type :dword
end

# Enable HTTP in Trusted Sites
windows_registry 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2' do
	values 'Flags' => 67
	type :dword
end

#Set Trusted Sites
node["trusted_sites"].each do |f|
	powershell "Create_Key" do
		code <<-EOF
			$reg = Get-WmiObject -List "StdRegProv" -Namespace "root\\default" -ErrorAction Stop
			$reg.SetDWORDValue(2147483650,"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\Zones\\2","Flags",67) > $null
			$reg.CreateKey(2147483650,"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\ZoneMap\\Domains\\#{f}") > $null
			$reg.CreateKey(2147483650,"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\ZoneMap\\EscDomains\\#{f}") > $null
		
			$reg.SetDWORDValue(2147483649,"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\Zones\\2","Flags",67) > $null
			$reg.CreateKey(2147483649,"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\ZoneMap\\Domains\\#{f}") > $null
			$reg.CreateKey(2147483649,"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\ZoneMap\\EscDomains\\#{f}") > $null
		EOF
	end
end

node["trusted_sites"].each do |f|
	windows_registry "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\ZoneMap\\Domains\\#{f}" do
		values 'http' => 2, 'https' => 2
		type :dword
	end

	windows_registry "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\ZoneMap\\EscDomains\\#{f}" do
		values 'http' => 2, 'https' => 2
		type :dword
	end

	windows_registry "HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\ZoneMap\\Domains\\#{f}" do
		values 'http' => 2, 'https' => 2
		type :dword
	end

	windows_registry "HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\ZoneMap\\EscDomains\\#{f}" do
		values 'http' => 2, 'https' => 2
		type :dword
	end
end
##
#
# Cookbook Name:: win_rolefeatures
# Recipe:: default
# Notes: For any issue found in this recipe, contact laguja2@csc.com or jgarcia58@csc.com
# Description: This recipe includes actions to install and remove Windows Server roles and features
#
# Copyright 2015, CSC-FSG-AWS "To be used internally"

# Install Dependency
::Chef::Recipe.send(:include, Windows::Helper)

# Install IIS Web Server Role
windows_feature 'IIS-WebServerRole' do
	action :install
end

# Use DISM to install Server Roles and Features
#-- Install IIS Web Features
%w{IIS-WebServer IIS-CommonHttpFeatures IIS-ApplicationDevelopment IIS-Security IIS-Performance IIS-HealthAndDiagnostics}.each do |f|
	windows_feature f do
		action :install
	end
end

%w{IIS-DefaultDocument IIS-DirectoryBrowsing IIS-HttpErrors IIS-StaticContent IIS-HttpRedirect IIS-HttpLogging IIS-HttpCompressionStatic IIS-HttpCompressionDynamic IIS-RequestFiltering}.each do |f|
	windows_feature f do
		action :install
	end
end

%w{IIS-ApplicationInit IIS-ISAPIExtensions IIS-ISAPIFilter IIS-CGI IIS-ServerSideIncludes IIS-WebSockets}.each do |f|
	windows_feature f do
		action :install
	end
end
#--

#-- Remove WebDAV Publishing feature
windows_feature 'IIS-WebDAV' do
	action :remove		
end

#-- Install IIS FTP Server Role
windows_feature 'IIS-FTPServer' do
	action :install
end

#-- Install IIS FTP Services
%w{IIS-FTPSvc IIS-FTPExtensibility}.each do |f|
	windows_feature f do
		action :install
	end
end

#-- Install IIS Management Tools
%w{IIS-WebServerManagementTools IIS-ManagementConsole IIS-IIS6ManagementCompatibility IIS-ManagementScriptingTools IIS-LegacySnapIn IIS-Metabase IIS-WMICompatibility IIS-LegacyScripts}.each do |f|
	windows_feature f do
		action :install
	end
end

#-- Install File Server Role
windows_feature 'FileAndStorage-Services' do
	action :install	
end

#-- Install File Server services
%w{File-Services File-Services-Search-Service}.each do |f|
	windows_feature f do
		action :install
	end
end
##

# Use PowerShell cookbook to install other services not supported by DISM
#-- Install .NET Framework 4.5
powershell "install_NET_Framework_4_5" do
	code <<-EOF
	Import-Module ServerManager
	Add-WindowsFeature -Name Application-Server
	Add-WindowsFeature -Name AS-NET-Framework
	EOF
end

#-- Install IIS features not installed by dism
powershell "install_IIS_Features" do
	code <<-EOF
	Import-Module ServerManager
	$IISFeatures = @()
	foreach ($feature in 'Web-Server','Web-WebServer','Web-App-Dev','Web-Net-Ext','Web-Net-Ext45','Web-ASP','Web-Asp-Net','Web-Asp-Net45') {
		$IISFeatures += $feature
	}
	Add-WindowsFeature -Name $IISFeatures
	EOF
end

#-- Install SMTP Server
# powershell "install_SMTP_Server" do
# 	code <<-EOF
# 	Import-Module ServerManager
# 	Add-WindowsFeature -Name SMTP-Server
# 	EOF
# end

#-- Install IIS Management Service
powershell "install_IIS_Mgmt_Service" do
	code <<-EOF
	Import-Module ServerManager
	Add-WindowsFeature -Name Web-Mgmt-Service
	EOF
end
##
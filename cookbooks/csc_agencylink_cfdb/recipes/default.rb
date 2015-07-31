#
# Cookbook Name:: csc_agencylink_cfdb
# Recipe:: default
# Notes: For any issue found in this recipe, contact laguja2@csc.com or jgarcia58@csc.com
# Description: This recipe includes actions to install prerequisites for AgencyLink CFDB
#
# Copyright 2015, CSC-FSG-AWS "To be used internally"

# IMPORTANT: Current BUG - KB2918614 causes access denied error 1603
# Remove this security update on the target Windows server for now - there is no fix for this at this time

#- Get FTP server information from Data_Bag_Item (ftp, directory)
ftp_path = data_bag_item('ftp', 'directory')
ftp_directory = ftp_path["installer_directory"]
ftp_server = ftp_path["server"]
ftp_secret = ftp_path["key_name"]
ftp_keypath = ftp_path["key_path"]

 #-- Decrypt and get credential information
ftp_key = Chef::EncryptedDataBagItem.load_secret("ftp://#{ftp_server}/#{ftp_keypath}")
ftp_cred  = Chef::EncryptedDataBagItem.load("ftp", "user", ftp_key)
ftp_user = ftp_cred["username"]
ftp_password = ftp_cred["password"]

cfdb_cred = Chef::EncryptedDataBagItem.load("agencylink", "cfdb_users", ftp_key)
sql_admin = cfdb_cred["sql_admin"]
sa_password = cfdb_cred["sa_password"]
tomcat_managergui_user = cfdb_cred["tomcat_managergui_user"]
tomcat_managergui_password = cfdb_cred["tomcat_managergui_password"]

#- Get FTP package information for Notepad++ from Data_Bag_Item (ftp, directory)
ftp_package = data_bag_item('ftp', 'package')
ftp_file_jre = ftp_package["Install_File_JRE"]
ftp_file_tomcat = ftp_package["Install_File_Tomcat"]
ftp_file_sqlserver = ftp_package["Install_File_SQLServer"]
ftp_path_sqlserver = ftp_package["Install_Path_SQLServer"]

#- Get install information for AgencyLink CFDB prerequisites
cfdb_package = data_bag_item('agencylink', 'cfdb')
jre_install_path = cfdb_package["jre_install_path"]
tomcat_install_path = cfdb_package["tomcat_install_path"]
tomcat_shutdown_port = cfdb_package["tomcat_shutdown_port"]
tomcat_http_port = cfdb_package["tomcat_http_port"]
tomcat_ajp_port = cfdb_package["tomcat_ajp_port"]
tomcat_service_name = cfdb_package["tomcat_service_name"]
tomcat_serverxml_path = cfdb_package["tomcat_serverxml_path"]
tomcat_usersxml_path = cfdb_package["tomcat_usersxml_path"]
commfw_archive_name = cfdb_package["commfw_archive_name"]
commfw_archive_path = cfdb_package["commfw_archive_path"]
replay_result_path = cfdb_package["replay_result_path"]
replay_working_path = cfdb_package["replay_working_path"]

# Define Installer URLs
installer_source_JRE = "ftp://#{ftp_user}:#{ftp_password}@#{ftp_server}/#{ftp_directory}/#{ftp_file_jre}"
installer_source_Tomcat = "ftp://#{ftp_user}:#{ftp_password}@#{ftp_server}/#{ftp_directory}/#{ftp_file_tomcat}"

# PRE-STEPS: Create temporary directories
directory 'C:\Temp' do
	recursive true
	action :create
	not_if { ::File.directory?('C:\Temp') }
end

directory 'C:\Temp\COMMFW' do
	recursive true
	action :create
	not_if { ::File.directory?('C:\Temp\COMMFW') }
end

directory 'C:\Temp\SQLInstall' do
	recursive true
	action :create
	not_if { ::File.directory?('C:\Temp\SQLInstall') }
end

directory "#{replay_result_path}" do
	recursive true
	action :create
	not_if { ::File.directory?("#{replay_result_path}") }
end

directory "#{replay_working_path}" do
	recursive true
	action :create
	not_if { ::File.directory?("#{replay_working_path}") }
end

# STEP 1: Install JRE
windows_package 'Java 8 Update 45 (64-bit)' do
	source installer_source_JRE
	action :install
	installer_type :custom
	options "/s INSTALLDIR=\"#{jre_install_path}\""
end

# STEP 2: Install Tomcat 8
windows_package 'Tomcat 8' do
	source installer_source_Tomcat
	action :install
	installer_type :custom
	options "/S /D=\"#{tomcat_install_path}\""
end

# Step 2 substep 1: Stop Tomcat service
windows_service 'Tomcat8' do
  action :stop
end

# Step 2 substep 2: Set values in server.xml
powershell 'Set-ServerXML-Ports' do
	code <<-EOH
		$linesToSearch = Get-Content -Path "#{tomcat_serverxml_path}"
		$HTTP_search = '    <Connector port="8080" protocol="HTTP/1.1"'
		$HTTP_search2 = '               port="8080" protocol="HTTP/1.1"'
		$AJP_search = '    <Connector port="8009" protocol="AJP/1.3" redirectPort="8443" />'
		$Shutdown_search = '<Server port="8005" shutdown="SHUTDOWN">'
		$HTTP_port = #{tomcat_http_port}
		$AJP_port = #{tomcat_ajp_port}
		$Shutdown_port = #{tomcat_shutdown_port}
		$newlines = ""
		foreach ($line in $linesToSearch) {
		    if ($line -like "*$HTTP_search*") {
		        $newlines += ('    <Connector port="' + "$HTTP_port" + '" protocol="HTTP/1.1"' + "`r`n") 
		    }
		    elseif ($line -like "*$HTTP_search2*") {
		    	$newlines += ('               port="' + "$HTTP_port" + '" protocol="HTTP/1.1"' + "`r`n")
		    }
		    elseif ($line -like "*$AJP_search*") {
		    	$newlines += ('    <Connector port="' + "$AJP_port" + '" protocol="AJP/1.3" redirectPort="8443" />' + "`r`n")
		    }
		    elseif ($line -like "*$Shutdown_search*") {
		    	$newlines += ('<Server port="' + "$Shutdown_port" + '" shutdown="SHUTDOWN">' + "`r`n")
		    }
		    else {
		        $newlines += ($line + "`r`n")
		    }
		}
		Set-Content -Path "#{tomcat_serverxml_path}" -Value $newlines -Force -Encoding UTF8
	EOH
end

# Step 2 substep 3: Create a Tomcat Manager UI admin
powershell 'Set-ManagerGUIuser' do
	code <<-EOH
		$userFile = Get-Content -Path "#{tomcat_usersxml_path}"
		$oldLine = '</tomcat-users>'
		$newLine = "  <user username=`"#{tomcat_managergui_user}`" password=`"#{tomcat_managergui_password}`" roles=`"manager-gui`" />`r`n</tomcat-users>"
		$newlines = ""
		foreach ($line in $userFile) {
			if ($line -eq $oldLine) {
				$newlines += ($newLine + "`r`n")
			}
			else {
				$newlines += ($line + "`r`n")
			}
		}
		Set-Content -Path "#{tomcat_usersxml_path}" -Value $newlines -Force -Encoding UTF8
	EOH
end

# STEP 3: Extract COMMFW files
# Step 3 substep 1: Get COMMFW archive
remote_file "c:\\Temp\\COMMFW\\#{commfw_archive_name}" do
  source "ftp://#{ftp_user}:#{ftp_password}@#{ftp_server}/#{ftp_directory}/#{commfw_archive_name}"
  action :create_if_missing
end

# Step 3 substep 2: Extract SQL Server Installer
windows_zipfile "#{commfw_archive_path}" do
  source "c:\\Temp\\COMMFW\\#{commfw_archive_name}"
  action :unzip
end

# Step 3 substep 3: Remove install files on target node
directory 'C:\Temp\COMMFW' do
	recursive true
	action :delete
end

# STEP 4: Start Tomcat service
windows_service 'Tomcat8' do
  action :start
end

# STEP 5: Install SQL Server 2012
# Step 5 substep 1: Get SQL Server install file
remote_file "c:\\Temp\\SQLInstall\\#{ftp_file_sqlserver}" do
  source "ftp://#{ftp_user}:#{ftp_password}@#{ftp_server}/#{ftp_directory}/#{ftp_file_sqlserver}"
  action :create_if_missing
end

# STEP 5 substep 2: Extract SQL Server Installer
windows_zipfile 'c:/Temp/SQLInstall' do
  source "c:/Temp/SQLInstall/#{ftp_file_sqlserver}"
  action :unzip
end

# STEP 5 substep 3: Transfer configuration file to SQL Server Installer path
cookbook_file "C:\\Temp\\SQLInstall\\#{ftp_path_sqlserver}\\ConfigurationFile.ini" do
	source 'ConfigurationFile.ini'
	action :create
end

# STEP 5 substep 4: Install SQL Server
dsc_script 'InstallSQLServer' do
  code <<-EOH
    Package SQLServer
    {
      ensure = 'Present'
      name = 'Microsoft SQL Server 2012 (64-bit)'
      productid = '7f121c35-f095-47aa-bc04-d214bc04727a'
      path = "#{ENV['SYSTEMDRIVE']}/Temp/SQLInstall/#{ftp_path_sqlserver}/setup.exe"
      arguments = "/ConfigurationFile=C:\\Temp\\SQLInstall\\#{ftp_path_sqlserver}\\ConfigurationFile.ini /SAPWD=#{sa_password}"
    }
  EOH
  timeout 3600
end

# STEP 5 substep 5: Remove install files on target node
directory 'C:\Temp\SQLInstall' do
	recursive true
	action :delete
end

### ALL STEPS COMPLETED ###
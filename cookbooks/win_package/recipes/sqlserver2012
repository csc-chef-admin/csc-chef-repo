# Recipe Name:: win_sqlserver2012
# Notes: For any issue found in this recipe, contact laguja2@csc.com or jgarcia58@csc.com
# Description: This recipe includes actions to install and configure SQL Server 2012
#
# Copyright 2015, CSC-FSG-AWS "To be used internally"

# Install Dependency
::Chef::Recipe.send(:include, Windows::Helper)

#- Get FTP server information from Data_Bag_Item (ftp, path)
ftp_path = data_bag_item('ftp', 'path')
ftp_directory = ftp_path["directory"]
ftp_server = ftp_path["server"]
ftp_url = ftp_path["url"]
ftp_secret = ftp_path["key_name"]
ftp_keypath = ftp_path["key_path"]

#-- Decrypt and get credential information from Data_Bag ftp, user
ftp_key = Chef::EncryptedDataBagItem.load_secret("ftp://#{ftp_server}/#{ftp_keypath}")
ftp_cred  = Chef::EncryptedDataBagItem.load("ftp", "user", ftp_key)
ftp_user = ftp_cred["username"]
ftp_password = ftp_cred["password"] 

#-- Get decrypted sa password
sapwd_file  = Chef::EncryptedDataBagItem.load("sqlserver", "sapwd", ftp_key)
sa_password = sapwd_file["sa_password"] 

#- Get SQL Server install information from Data_Bag sqlserver
sql_package = data_bag_item('packages', 'installers')
ftp_file_sqlserver = sql_package["sql_server_2012"]

sql_paths = data_bag_item('sqlserver', 'path')
sql_install_dir = sql_paths["install_dir"]
sql_installer_dir = sql_paths["installer_dir"]
sql_shared_install_dir = sql_paths["shared_install_dir"]
sql_shared_install_wow64 = sql_paths["shared_install_wow64"]
sql_replay_result_path = sql_paths["replay_result_path"]
sql_replay_working_path = sql_paths["replay_working_path"]
sql_analysis_services_data = sql_paths["analysis_services_data"]
sql_analysis_services_log = sql_paths["analysis_services_log"]
sql_analysis_services_backup = sql_paths["analysis_services_backup"]
sql_analysis_services_temp = sql_paths["analysis_services_temp"]
sql_analysis_services_config = sql_paths["analysis_services_config"]

sql_users = data_bag_item('sqlserver', 'admins')
sql_sysadmin_user = sql_users["sysadmin_user"]
sql_analysis_service_user = sql_users["analysis_service_user"]
sql_relay_controller_user = sql_users["relay_controller_user"]

# Create temporary directories
directory 'C:\Temp\SQLInstall' do
	recursive true
	action :create
	not_if { ::File.directory?('C:\Temp\SQLInstall') }
end

for dir_create in [ sql_install_dir, sql_shared_install_dir, sql_shared_install_wow64, sql_replay_result_path, sql_replay_working_path, sql_analysis_services_data, sql_analysis_services_log, sql_analysis_services_backup, sql_analysis_services_temp, sql_analysis_services_config ] do
	directory "create_directory" do
		recursive true
		path dir_create
		action :create
		not_if { ::File.directory?(dir_create) }
	end
end

# Get SQL Server install file
remote_file 'sql-installer' do
  path "c:\\Temp\\SQLInstall\\#{ftp_file_sqlserver}"
  source "ftp://#{ftp_user}:#{ftp_password}@#{ftp_url}/#{ftp_file_sqlserver}"
  action :nothing
end

# Extract SQL Server Installer
windows_zipfile 'extract-installer' do
  path 'c:/Temp/SQLInstall'
  source "c:/Temp/SQLInstall/#{ftp_file_sqlserver}"
  action :nothing
end

# Perform extraction if installer if it does not exist
directory 'check-installer' do
	notifies :create_if_missing, 'remote_file[sql-installer]', :immediately
	notifies :unzip, 'windows_zipfile[extract-installer]', :immediately
	# not_if { ::File.directory?('C:\Temp\SQLInstall') }
end

# Transfer configuration file to SQL Server Installer path
cookbook_file "C:\\Temp\\SQLInstall\\#{sql_installer_dir}\\ConfigurationFile.ini" do
	source 'ConfigurationFile.ini'
	action :create
end

# Set ConfigurationFile.ini items
powershell 'Set-Install-Configuration' do
	code <<-EOH
		$linesToSearch = Get-Content -Path "C:\\Temp\\SQLInstall\\#{sql_installer_dir}\\ConfigurationFile.ini"
		foreach ($line in $linesToSearch) {
		    if ($line -like "*INSTANCEDIR*") {
		        $newlines += ('INSTANCEDIR="#{sql_install_dir}"' + "`r`n")
		    }
		    elseif ($line -like "*INSTALLSHAREDDIR*") {
		    	$newlines += ('INSTALLSHAREDDIR="#{sql_shared_install_dir}"' + "`r`n")
		    }
		    elseif ($line -like "*INSTALLSHAREDWOWDIR*") {
		    	$newlines += ('INSTALLSHAREDWOWDIR="#{sql_shared_install_wow64}"' + "`r`n")
		    }
		    elseif ($line -like "*CLTRESULTDIR*") {
		    	$newlines += ('INSTALLSHAREDWOWDIR="#{sql_replay_result_path}"' + "`r`n")
		    }
			elseif ($line -like "*CLTWORKINGDIR*") {
		    	$newlines += ('CLTWORKINGDIR="#{sql_replay_working_path}"' + "`r`n")
		    }
			elseif ($line -like "*ASDATADIR*") {
		    	$newlines += ('ASDATADIR="#{sql_analysis_services_data}"' + "`r`n")
		    }
			elseif ($line -like "*ASLOGDIR*") {
		    	$newlines += ('ASLOGDIR="#{sql_analysis_services_log}"' + "`r`n")
		    }
			elseif ($line -like "*ASBACKUPDIR*") {
		    	$newlines += ('ASLOGDIR="#{sql_analysis_services_backup}"' + "`r`n")
		    }
			elseif ($line -like "*ASTEMPDIR*") {
		    	$newlines += ('ASTEMPDIR="#{sql_analysis_services_temp}"' + "`r`n")
		    }
			elseif ($line -like "*ASCONFIGDIR*") {
		    	$newlines += ('ASCONFIGDIR="#{sql_analysis_services_config}"' + "`r`n")
		    }
			elseif ($line -like "*CTLRUSERS*") {
		    	$newlines += ('CTLRUSERS="#{sql_relay_controller_user}"' + "`r`n")
		    }
			elseif ($line -like "*ASSYSADMINACCOUNTS*") {
		    	$newlines += ('ASSYSADMINACCOUNTS="#{sql_analysis_service_user}"' + "`r`n")
		    }
			elseif ($line -like "*SQLSYSADMINACCOUNTS*") {
		    	$newlines += ('SQLSYSADMINACCOUNTS="#{sql_sysadmin_user}"' + "`r`n")
		    }
		    else {
		        $newlines += ($line + "`r`n")
		    }
		}
		Set-Content -Path "C:\\Temp\\SQLInstall\\#{sql_installer_dir}\\ConfigurationFile.ini" -Value $newlines -Force -Encoding UTF8
	EOH
end

# Install SQL Server
dsc_script 'InstallSQLServer' do
  code <<-EOH
    Package SQLServer
    {
      ensure = 'Present'
      name = 'Microsoft SQL Server 2012 (64-bit)'
      productid = '7f121c35-f095-47aa-bc04-d214bc04727a'
      path = "#{ENV['SYSTEMDRIVE']}/Temp/SQLInstall/#{sql_installer_dir}/setup.exe"
      arguments = "/ConfigurationFile=C:\\Temp\\SQLInstall\\#{sql_installer_dir}\\ConfigurationFile.ini /SAPWD=#{sa_password}"
    }
  EOH
  timeout 3600
end

# Create SQL Management Studio shortcut
all_users_desktop = WIN32OLE.new("WScript.Shell").SpecialFolders("AllUsersDesktop")
windows_shortcut "#{all_users_desktop}/SQL Server Management Studio.lnk" do
    target "#{sql_install_dir}\\DReplayClient\\ResultDir\\110\\Tools\\Binn\\ManagementStudio\\Ssms.exe"
    description "Launch SQL Server Management Studio"
    iconlocation "#{sql_replay_result_path}\\110\\Tools\\Binn\\ManagementStudio\\Ssms.exe, 0"
end

# Remove install files on target node
directory 'C:\Temp\SQLInstall' do
	recursive true
	action :delete
end
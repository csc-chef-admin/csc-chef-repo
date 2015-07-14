#
# Cookbook Name:: win_package
# Recipe:: default
# Notes: For any issue found in this recipe, contact laguja2@csc.com or jgarcia58@csc.com
# Description: This recipe includes actions to install packaged applications on Windows nodes
#
# Copyright 2015, CSC-FSG-AWS "To be used internally"

# IMPORTANT: Current BUG - KB2918614 causes access denied error 1603
# Remove this security update on the target Windows server for now - there is no fix for this at this time

#- Get FTP server information from Data_Bag_Item (ftp, path)
ftp_path = data_bag_item('ftp', 'path')
ftp_directory = ftp_path["directory"]
ftp_server = ftp_path["server"]
ftp_url = ftp_path["url"]
ftp_secret = ftp_path["key_name"]
ftp_keypath = ftp_path["key_path"]

 #-- Decrypt and get credential information from Data_Bag ftp, user
# ftp_key = Chef::EncryptedDataBagItem.load_secret("C:\\#{ftp_secret}")
ftp_key = Chef::EncryptedDataBagItem.load_secret("ftp://#{ftp_server}/#{ftp_keypath}")
ftp_cred  = Chef::EncryptedDataBagItem.load("ftp", "user", ftp_key)
ftp_user = ftp_cred["username"]
ftp_password = ftp_cred["password"] 

#- Get FTP package information from Data_Bag_Item (ftp, path)
ftp_package = data_bag_item('ftp', 'package')
#-- WinZip 19 Installer
ftp_file_winzip = ftp_package["Install_File_WinZip"]
ftp_file_winzip_log = ftp_package["Install_File_WinZip_Log"]
#-- SQL Native Client Installer
ftp_file_sqlclient = ftp_package["Install_File_SQLClient"]
ftp_file_sqlclient_log = ftp_package["Install_File_SQLClient_Log"]
#-- SQL Management Studio
ftp_file_sqlmgmtstudio = ftp_package["Install_File_SQLMgmtStudio"]
ftp_file_sqlmgmtstudio_log = ftp_package["Install_File_SQLMgmtStudio_Log"]
ftp_file_sqlmgmtstudio_path = ftp_package["Install_File_SQLMgmtStudio_Path"]

# Define Installer URLs
installer_source_WinZip = "ftp://#{ftp_user}:#{ftp_password}@#{ftp_url}/#{ftp_file_winzip}"
installer_source_SQLClient = "ftp://#{ftp_user}:#{ftp_password}@#{ftp_url}/#{ftp_file_sqlclient}"
installer_source_SQLMgmtStudio = "ftp://#{ftp_user}:#{ftp_password}@#{ftp_url}/#{ftp_file_sqlmgmtstudio}"
##

# Reboot after package install
reboot 'Reboot Node' do
  action :nothing
end

#** Begin INSTALLATION PROPER **
# Install WinZip
windows_package 'WinZip 19.5' do
  source installer_source_WinZip
  action :install
  # options "/lv #{ftp_file_winzip_log}"
end

# Install SQL Native Client
windows_package 'SQL Native Client' do
  source installer_source_SQLClient
  action :install
  # options "/lv #{ftp_file_sqlclient_log} IACCEPTSQLNCLILICENSETERMS=YES"
  options "IACCEPTSQLNCLILICENSETERMS=YES"
end

# Install SQL Management Studio
remote_file "c:\\#{ftp_file_sqlmgmtstudio}" do
  source "ftp://#{ftp_user}:#{ftp_password}@#{ftp_url}/#{ftp_file_sqlmgmtstudio}"
  action :create_if_missing
end

dsc_script 'InstallSQLMgmtStudio' do
  code <<-EOH
    Package SQLMgmtStudio
    {
      ensure = 'Present'
      name = 'SQL Server 2012 Management Studio'
      productid = '26BFF1F1-5C03-4C55-9C7C-FD65889AFA70'
      path = "#{ENV['SYSTEMDRIVE']}/Installers/SQLManagementStudio_x64_ENU.exe"
      arguments = "/Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=install /FEATURES=SSMS"
    }
  EOH
end

file "c:\\#{ftp_file_sqlmgmtstudio}" do
  action :delete
end

require 'win32ole'
all_users_desktop = WIN32OLE.new("WScript.Shell").SpecialFolders("AllUsersDesktop")

windows_shortcut "#{all_users_desktop}/SQL Management Studio 2012.lnk" do
    target "#{ftp_file_sqlmgmtstudio_path}"
    description "Launch SQL Server Management Studio 2012"
    iconlocation "#{ftp_file_sqlmgmtstudio_path}, 0"
end
##

# Reboot now!
execute 'Reboot Node Now' do
  command 'cd .'
  notifies :reboot_now, 'reboot[Reboot Node]', :immediately
end
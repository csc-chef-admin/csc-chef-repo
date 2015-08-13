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
ftp_package = data_bag_item('packages', 'installers')
ftp_file_sqlmgmtstudio = ftp_package["sql_management_studio_2012"]

ftp_package = data_bag_item('packages', 'path')
ftp_file_sqlmgmtstudio_log = ftp_package["sql_management_studio_log"]
ftp_file_sqlmgmtstudio_path = ftp_package["sql_management_studio_path"]

# Define Installer URL
installer_source_SQLMgmtStudio = "ftp://#{ftp_user}:#{ftp_password}@#{ftp_url}/#{ftp_file_sqlmgmtstudio}"

# Install SQL Management Studio
remote_file "c:\\Temp\\#{ftp_file_sqlmgmtstudio}" do
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
      path = "#{ENV['SYSTEMDRIVE']}/Temp/SQLManagementStudio_x64_ENU.exe"
      arguments = "/Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=install /FEATURES=SSMS"
    }
  EOH
end

file "c:\\Temp\\#{ftp_file_sqlmgmtstudio}" do
  action :delete
end

require 'win32ole'
all_users_desktop = WIN32OLE.new("WScript.Shell").SpecialFolders("AllUsersDesktop")

windows_shortcut "#{all_users_desktop}/SQL Management Studio 2012.lnk" do
    target "#{ftp_file_sqlmgmtstudio_path}"
    description "Launch SQL Server Management Studio 2012"
    iconlocation "#{ftp_file_sqlmgmtstudio_path}, 0"
end
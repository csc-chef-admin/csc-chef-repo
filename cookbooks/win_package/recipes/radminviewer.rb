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

#- Get FTP package information for JRE from Data_Bag packages
radmin_package = data_bag_item('packages', 'installers')
ftp_file_radmin = radmin_package["radmin_viewer"]

# Define Installer URLs
installer_source_RAdmin = "ftp://#{ftp_user}:#{ftp_password}@#{ftp_url}/#{ftp_file_radmin}"

# Install RAdmin Server
windows_package 'RAdmin 3.5' do
  source installer_source_RAdmin
  action :install
end

require 'win32ole'
all_users_desktop = WIN32OLE.new("WScript.Shell").SpecialFolders("AllUsersDesktop")

windows_shortcut "#{all_users_desktop}/RAdmin Viewer.lnk" do
    target "C:\\Program Files (x86)\\Radmin Viewer 3\\Radmin.exe"
    description "Launch RAdmin Viewer 3.5"
    iconlocation "C:\\Program Files (x86)\\Radmin Viewer 3\\Radmin.exe, 0"
end
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

#- Get FTP package information for Notepad++ from Data_Bag_Item (ftp, path)
ftp_package = data_bag_item('ftp', 'package')
ftp_file_putty = ftp_package["Install_File_PuTTY"]
ftp_file_putty_path = ftp_package["Install_File_PuTTY_Path"]

# Define Installer URLs
installer_source_PuTTY = "ftp://#{ftp_user}:#{ftp_password}@#{ftp_url}/#{ftp_file_putty}"

#- Install PuTTY
windows_package 'PuTTY release 0.64' do
  source installer_source_PuTTY
  installer_type :inno
  action :install
end

require 'win32ole'
all_users_desktop = WIN32OLE.new("WScript.Shell").SpecialFolders("AllUsersDesktop")

windows_shortcut "#{all_users_desktop}/PuTTY.lnk" do
    target "#{ftp_file_putty_path}"
    description "Launch PuTTY"
    iconlocation "#{ftp_file_putty_path}, 0"
end
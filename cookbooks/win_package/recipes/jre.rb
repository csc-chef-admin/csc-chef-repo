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
ftp_file_jre = ftp_package["Install_File_JRE"]
ftp_file_jre_path = ftp_package["Install_File_JRE_Install"]

# Define Installer URLs
installer_source_JRE = "ftp://#{ftp_user}:#{ftp_password}@#{ftp_url}/#{ftp_file_jre}"

#- Install JRE
windows_package 'Java 8 Update 45 (64-bit)' do
	source installer_source_JRE
	action :install
	installer_type :custom
	options "/s INSTALLDIR=#{ftp_file_jre_path}"
end
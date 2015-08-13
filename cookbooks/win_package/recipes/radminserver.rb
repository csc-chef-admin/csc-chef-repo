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

#- Get FTP package information for JRE from Data_Bag packages
radmin_package = data_bag_item('packages', 'installers')
ftp_file_radmin = radmin_package["radmin_server"]

# Install RAdmin Server
directory 'C:\Temp\RAdminsetup' do
	recursive true
	action :create
	not_if { ::File.directory?('C:\Temp\RAdminsetup') }
end

remote_file 'radmin-installer' do
  path "c:\\Temp\\RAdminsetup\\#{ftp_file_radmin}"
  source "ftp://#{ftp_user}:#{ftp_password}@#{ftp_url}/#{ftp_file_radmin}"
  action :create_if_missing
end

execute 'install-radminserver' do
	command "msiexec.exe /i \"C:\\Temp\\RAdminsetup\\#{ftp_file_radmin}\" /qn /norestart"
	action :run
	returns 3010
end

directory 'C:\Temp\RAdminsetup' do
	recursive true
	action :delete
end
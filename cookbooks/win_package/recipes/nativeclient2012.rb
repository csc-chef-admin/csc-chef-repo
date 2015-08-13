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
nclient_package = data_bag_item('packages', 'installers')
ftp_file_sqlclient = nclient_package["sqlclient"]

nclient_package = data_bag_item('packages', 'path')
ftp_file_sqlclient_log = nclient_package["sql_client_log"]

# Define Installer URLs
installer_source_SQLClient = "ftp://#{ftp_user}:#{ftp_password}@#{ftp_url}/#{ftp_file_sqlclient}"

# Install SQL Native Client
windows_package 'SQL Native Client' do
  source installer_source_SQLClient
  action :install
  # options "/lv #{ftp_file_sqlclient_log} IACCEPTSQLNCLILICENSETERMS=YES"
  options "IACCEPTSQLNCLILICENSETERMS=YES"
end
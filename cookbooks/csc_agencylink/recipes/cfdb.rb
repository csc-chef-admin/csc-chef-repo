#
# Cookbook Name:: csc_agencylink
# Recipe:: cfdb
# Notes: For any issue found in this recipe, contact laguja2@csc.com or jgarcia58@csc.com
# Description: This recipe includes actions to install prerequisites for AgencyLink CFDB
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

 #-- Decrypt and get credential information
ftp_key = Chef::EncryptedDataBagItem.load_secret("ftp://#{ftp_server}/#{ftp_keypath}")
ftp_cred  = Chef::EncryptedDataBagItem.load("ftp", "user", ftp_key)
ftp_user = ftp_cred["username"]
ftp_password = ftp_cred["password"]

#- Get install information for AgencyLink CFDB prerequisites
cfdb_package = data_bag_item('agencylink', 'cfdb')
commfw_archive_name = cfdb_package["commfw_archive_name"]
commfw_archive_path = cfdb_package["commfw_archive_path"]

# PREREQUISITE 1: Install JRE
include_recipe 'win_package::jre'

# PREREQUISITE 2: Install Tomcat
include_recipe 'win_package::tomcat'

# PREREQUISITE 3: Install SQL Server 2012
include_recipe 'win_package::sqlserver2012'
# ***** PRERESUITEIS COMPLETE *****

# Create temporary directories
directory 'C:\Temp\COMMFW' do
	recursive true
	action :create
	not_if { ::File.directory?('C:\Temp\COMMFW') }
end

# Get COMMFW archive
remote_file "c:\\Temp\\COMMFW\\#{commfw_archive_name}" do
  source "ftp://#{ftp_user}:#{ftp_password}@#{ftp_url}/#{commfw_archive_name}"
  action :create_if_missing
end

# Extract COMMFW files
windows_zipfile "#{commfw_archive_path}" do
  source "c:\\Temp\\COMMFW\\#{commfw_archive_name}"
  action :unzip
end

# Cleanup: Remove temporary COMMFW archive
directory 'C:\Temp\COMMFW' do
	recursive true
	action :delete
end

### ALL STEPS COMPLETED ###
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

#- Get FTP package information from Data Bag 'packages'
ftp_package = data_bag_item('packages', 'installers')
ftp_file_tomcat = ftp_package["tomcat"]

#- Get tomcat install information from Data Bag 'tomcat'
tomcat_attrib = data_bag_item('tomcat', 'directory')
tomcat_install_path = tomcat_attrib["install_path"]
tomcat_serverxml_path = tomcat_attrib["serverxml_path"]
tomcat_usersxml_path = tomcat_attrib["usersxml_path"]

tomcat_attrib = data_bag_item('tomcat', 'service')
tomcat_service_name = tomcat_attrib["service_name"]

tomcat_attrib = data_bag_item('tomcat', 'ports')
tomcat_http_port = tomcat_attrib["http_port"]
tomcat_shutdown_port = tomcat_attrib["shutdown_port"]
tomcat_ajp_port = tomcat_attrib["ajp_port"]

include_recipe 'win_package::jre'

#-- Get Tomcat Users to create
tomcat_cred = Chef::EncryptedDataBagItem.load("tomcat", "users", ftp_key)
tomcat_managergui_user = tomcat_cred["manager_gui_user"]
tomcat_managergui_password = tomcat_cred["manager_gui_password"]

# PREP: Create temporary directories
directory 'C:\Temp' do
	recursive true
	action :create
	not_if { ::File.directory?('C:\Temp') }
end

directory 'C:\Temp\Tomcat_Files' do
	recursive true
	action :create
	not_if { ::File.directory?('C:\Temp\Tomcat_Files') }
end

# Transfer Tomcat 8 archive
remote_file "c:\\Temp\\Tomcat_Files\\#{ftp_file_tomcat}" do
  source "ftp://#{ftp_user}:#{ftp_password}@#{ftp_server}/#{ftp_directory}/#{ftp_file_tomcat}"
  action :create_if_missing
end

# Extract Tomcat 8 archive
windows_zipfile "#{tomcat_install_path}" do
  source "c:\\Temp\\Tomcat_Files\\#{ftp_file_tomcat}"
  action :unzip
  not_if { ::File.directory?("#{tomcat_install_path}") }
end

cookbook_file "#{tomcat_install_path}\\tomcat_icon.ico" do
	source 'tomcat_icon.ico'
	action :create
end

# Remove temporary files
directory 'C:\Temp\Tomcat_Files' do
	recursive true
	action :delete
end

# Install Tomcat8 service
windows_batch 'install_tomcat_service' do
	code <<-EOH
		cd "#{tomcat_install_path}\\bin"
		service.bat install "#{tomcat_service_name}"
	EOH
end

# Create desktop shortcut for Tomcat 8
all_users_desktop = WIN32OLE.new("WScript.Shell").SpecialFolders("AllUsersDesktop")
windows_shortcut "#{all_users_desktop}/#{tomcat_service_name} Service.lnk" do
    target "#{tomcat_install_path}\\bin\\tomcat8w.exe"
    description "Launch Tomcat 8 Configuration"
    iconlocation "#{tomcat_install_path}\\bin\\tomcat8.exe, 0"
end

windows_shortcut "#{all_users_desktop}/#{tomcat_service_name} Manager.lnk" do
    target "http://localhost:#{tomcat_http_port}/manager/html"
    description "Launch Tomcat 8 Manager"
    iconlocation "#{tomcat_install_path}\\tomcat_icon.ico, 0"
end

# Set values in server.xml
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

# Create a Tomcat Manager UI admin
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

# Start Tomcat service
windows_service 'Tomcat8' do
  action :start
end
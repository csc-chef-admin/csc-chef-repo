# Reboot node at the end of chef client run

# Reboot after package install
reboot 'Reboot Node' do
  action :nothing
end

# Reboot now!
execute 'Reboot Node Now' do
  command 'cd .'
  notifies :reboot_now, 'reboot[Reboot Node]', :immediately
end
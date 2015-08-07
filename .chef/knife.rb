# See https://docs.getchef.com/config_rb_knife.html for more information on knife configuration options

current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "chef-admin"
client_key               "#{current_dir}/chef-admin.pem"
validation_client_name   "csc-fsg-aws-validator"
validation_key           "#{current_dir}/csc-fsg-aws-validator.pem"
chef_server_url          "https://chef-server.aws.csc-fsg.com/organizations/csc-fsg-aws"
cookbook_path            ["#{current_dir}/../cookbooks"]
knife[:editor] = "notepad"
knife[:secret_file] = "#{current_dir}/encrypted_data_bag_secret"
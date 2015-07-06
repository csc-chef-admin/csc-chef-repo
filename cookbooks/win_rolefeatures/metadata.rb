name             'win_rolefeatures'
maintainer       'Chef Admin'
maintainer_email 'chef-admin@aws.csc-fsg.com'
license          'All rights reserved'
description      'Installs/Configures windows roles, features, and services that should be running on deployed Windows servers'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

# Cookbook dependencies (IIS and Windows)
depends          'iis'
depends          'windows'
depends          'powershell'

supports         'windows'
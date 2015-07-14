name             'win_package'
maintainer       'Chef Admin'
maintainer_email 'chef-admin@aws.csc-fsg.com'
license          'All rights reserved'
description      'Installs packaged applications on managed Windows hosts'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

# Cookbook dependencies (IIS and Windows)
depends          'windows'
depends          'powershell'
depends 		 'dsc'
supports         'windows'
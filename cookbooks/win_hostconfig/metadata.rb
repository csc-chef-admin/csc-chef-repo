name             'win_hostconfig'
maintainer       'Chef Admin'
maintainer_email 'chef-admin@aws.csc-fsg.com'
license          'All rights reserved'
description      'Configures host settings for target node'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

# Cookbook dependencies (IIS and Windows)
depends          'windows'
depends          'powershell'

supports         'windows'
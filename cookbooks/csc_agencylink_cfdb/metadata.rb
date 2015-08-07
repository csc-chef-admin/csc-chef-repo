name             'csc_agencylink_cfdb'
maintainer       'Chef Admin'
maintainer_email 'chef-admin@aws.csc-fsg.com'
license          'All rights reserved'
description      'Installs/Configures AgencyLink CFDB components'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

# Cookbook dependencies (IIS and Windows)
depends          'iis'
depends          'windows'
depends          'powershell'

supports         'windows'
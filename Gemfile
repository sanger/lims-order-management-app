source "http://www.rubygems.org"
 
gemspec

gem 'lims-busclient', '~>0.1.0', :git => 'https://github.com/sanger/lims-busclient.git' , :branch => 'master'
gem 'lims-management-app', '~>1.2', :git => 'https://github.com/sanger/lims-management-app.git', :branch => 'development'

group :development do
  gem 'sqlite3', :platforms => :mri
end

group :debugger do
  gem 'debugger'
  gem 'debugger-completion'
  gem 'shotgun'
end

group :deployment do
  gem "psd_logger", :git => "http://github.com/sanger/psd_logger.git"
end

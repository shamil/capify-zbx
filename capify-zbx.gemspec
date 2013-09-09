# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "capify-zbx"
  s.version     = "0.0.2"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Alex Simenduev"]
  s.email       = ["shamil.si@gmail.com"]
  s.homepage    = "http://github.com/shamil/capify-zbx"
  s.summary     = %q{Grabs roles from Zabbix's host groups and autogenerates capistrano tasks}
  s.description = %q{Grabs roles from Zabbix's host groups and autogenerates capistrano tasks}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

# s.add_dependency 'zabbixapi', '>=0.6.0'
  s.add_dependency 'capistrano', '>=2.1.0'
  s.add_dependency 'colored'
end

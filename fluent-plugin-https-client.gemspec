# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = 'fluent-plugin-https-client'
  gem.version       = '0.0.1'
  gem.authors       = ['Arash Vatanpoor']
  gem.email         = ['arash@a-venture.org']
  gem.summary       = %q{A generic Fluentd output plugin to send records to HTTP / HTTPS endpoint}
  gem.description   = %q{A generic Fluentd output plugin to send records to HTTP / HTTPS endpoint, with SSL, Proxy, and Header implementation}
  gem.homepage      = 'https://github.com/a-venture/fluent-plugin-https-client'
  gem.license       = 'MIT'
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
  gem.required_ruby_version = '>= 2.1.2'

  gem.add_runtime_dependency 'yajl-ruby', '~> 1.0'
  gem.add_runtime_dependency 'fluentd', '~> 0.12'
end

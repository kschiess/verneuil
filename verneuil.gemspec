# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'verneuil'
  s.version = '0.1.0'

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.authors = ['Kaspar Schiess']
  s.date = '2011-02-02'
  s.email = 'kaspar.schiess@absurd.li'
  s.extra_rdoc_files = ['README']
  s.files = %w(Gemfile HISTORY.txt LICENSE Rakefile README) + Dir.glob("{lib,example}/**/*")
  s.homepage = 'http://kschiess.github.com/verneuil'
  s.rdoc_options = ['--main', 'README']
  s.require_paths = ['lib']
  s.rubygems_version = '1.3.7'
  s.summary = 'Artificial Rubies. Using a fusion process.'  
  
  s.add_dependency 'ruby_parser', '~> 2.0'
  
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'flexmock'
end

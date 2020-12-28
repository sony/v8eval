Gem::Specification.new 'v8eval', '1.0' do |s|
  s.name = 'v8eval'
  s.version = '0.3.0'
  s.licenses = ['MIT']
  s.description = 'Run JavaScript engine V8 in Ruby'
  s.summary = 'v8eval gem is ruby binding to the latest V8 and supports
               Linux and Mac OS X.'
  s.authors = ['Prateek Papriwal', 'Yoshiyuki Mineo']
  s.email = 'Yoshiyuki.Mineo@sony.com'
  s.homepage = 'https://github.com/sony/v8eval'
  s.extra_rdoc_files = ['README.md']

  s.files = Dir['ruby/**/*'] + Dir['src/**/*'] + Dir['build.sh']
  s.files += Dir['LICENSE'] + Dir['README.md'] + Dir['CMakeLists.txt'] +
             Dir['v8eval.gemspec']
  s.platform = Gem::Platform::RUBY
  s.require_paths = ['ruby/lib', 'ruby/ext']
  s.extensions = Dir['ruby/ext/**/extconf.rb']

  s.add_development_dependency 'rake', '>= 12.3.3'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'yard', '>= 0.9.11'

  s.required_ruby_version = '>= 2.0.0'
end

Gem::Specification.new do |spec|
  spec.name = 'dm-grape-hypertext_application_language'
  spec.version = '0.0.0'
  spec.summary = %q{Data Mapper and Grape extensions for Hypertext Application Language}
  spec.description = %q{}
  spec.homepage = 'http://stateless.co/hal_specification.html'
  spec.authors = ['Roy Ratcliffe']
  spec.email = ['roy@pioneeringsoftware.co.uk']
  spec.files = `git ls-files -z`.split("\x0")
  spec.license = 'MIT'

  spec.add_dependency 'grape-hypertext_application_language'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end

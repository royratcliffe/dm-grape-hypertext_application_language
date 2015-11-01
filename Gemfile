source 'https://rubygems.org'

gemspec

%w(dm grape).each do |ext|
  name = ext + '-hypertext_application_language'
  path File.join(File.dirname(__FILE__), '..', name) do
    gem name
  end
end

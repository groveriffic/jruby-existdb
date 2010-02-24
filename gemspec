spec = Gem::Specification.new do |s|
    s.name = 'jruby-existdb'
    s.version = '0.1'
    s.summary = 'Wrapper for eXistDB\'s XMLDB API Drivers'
    s.author = 'Sam Ehlers'
    s.require_paths = ['lib']
    s.files = Dir['lib/**/*.rb'] + Dir['lib/**/*.jar'] + Dir['*.xml']
end


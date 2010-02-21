require 'java' 
require 'uri'
require 'cgi' # For HTML Escaping
require 'forwardable'

$LOAD_PATH << File.dirname(__FILE__)


# Set System Properties
EXIST_HOME = File.dirname(__FILE__) + '/../' if not defined?(EXIST_HOME)
EXIST_LOGDIR = EXIST_HOME + '/logs' if not defined?(EXIST_LOGDIR)
{
    'exist.home' => EXIST_HOME,
    'exist.logdir' => EXIST_LOGDIR
}.each do |k,v|
    java.lang.System.setProperty(k,v)
end

# Ensure the directories exist
require 'fileutils'
FileUtils.mkdir_p EXIST_HOME + '/data'
FileUtils.mkdir_p EXIST_LOGDIR

# Copy the config files to the places where eXist will eXpect them.
[ 'conf.xml', 'log4j.xml' ].each do |config_file|
    src = "#{File.dirname(__FILE__)}/../#{config_file}"
    dest = "#{EXIST_HOME}/#{config_file}"
    FileUtils.copy(src, dest) if not File.exists?(dest)
end

# Load all the Jars
require 'find'
Find.find( File.dirname(__FILE__) + '/jars' ) do |path|
    next if File.extname(path) != '.jar'
    require path
end

require 'existdb/classwrap.rb'
require 'existdb/database_instance.rb'
require 'existdb/collection.rb'
require 'existdb/resource.rb'
require 'existdb/resource_set.rb'
require 'existdb/xquery_service.rb'

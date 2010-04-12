require 'java' 
require 'uri'
require 'cgi' # For HTML Escaping
require 'find'
require 'fileutils'
require 'forwardable'

$LOAD_PATH << File.dirname(__FILE__)

module ExistDB
  class SystemProperties
    class << self
      def home_directory
        defined?(EXIST_HOME) && EXIST_HOME || ENV['EXIST_HOME'] || '/var/spool/existdb'
      end
      
      def log_directory
        defined?(EXIST_LOG) && EXIST_LOG || ENV['EXIST_LOG'] || '/var/log/existdb'
      end

      def data_directory
        home_directory + '/data'
      end

      def init
        java.lang.System.setProperty('exist.home', home_directory)
        java.lang.System.setProperty('exist.logdir', log_directory)
      end

      def autocreate_config_files
        # Copy the config files to the places where eXist will eXpect them.
        # the log4j.xml file should be on your classpath to ensure proper logging
        [ 'conf.xml', 'log4j.xml' ].each do |config_file|
            src = "#{File.dirname(__FILE__)}/../#{config_file}"
            dest = "#{home_directory}/#{config_file}"
            FileUtils.copy(src, dest) if not File.exists?(dest)
        end
      end

      def autocreate_data_directory
        FileUtils.mkdir_p data_directory
      end

    end
    init
    autocreate_data_directory
    autocreate_config_files
  end
end

# Load eXistDB jars
Find.find( File.dirname(__FILE__) + '/jars' ) do |path|
  next if File.extname(path) != '.jar'
  require path
end

require 'existdb/classwrap.rb'
require 'existdb/collection.rb'

require 'existdb/resource/base.rb'
require 'existdb/resource/xml.rb'
require 'existdb/resource/binary.rb'
require 'existdb/resource_set.rb'

require 'existdb/xquery_service.rb'
require 'existdb/meta.rb'
require 'existdb/embedded.rb'
require 'existdb/xql_factory.rb'
require 'existdb/dom/mapper.rb'
require 'existdb/dom/active_record.rb'

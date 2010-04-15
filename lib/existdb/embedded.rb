module ExistDB
  class Embedded
    include Singleton

    attr_accessor :username, :password, :url, :properties

    def initialize
      @username ||= 'admin'
      @password ||= ''
      @properties ||= {'create-database' => 'true'}
      @url ||= "exist:///db"

      at_exit do
        stop if running?
      end
    end

    def start
      return false if running?
      @impl = org.exist.xmldb.DatabaseImpl.new
      @properties.each{ |key, value| @impl.setProperty(key.to_s, value.to_s) }
      org.xmldb.api.DatabaseManager.registerDatabase(@impl)
      @base_collection = @impl.getCollection(@url, @username, @password)
      @database_instance_manager = @base_collection.getService('DatabaseInstanceManager', '1.0')
      @collection_manager = @base_collection.getService('CollectionManager', '1.0')

      true
    end

    def running?
      @database_instance_manager.getStatus
      true
    rescue
      false
    end

    alias :started? :running? 

    def stop
      @database_instance_manager.shutdown
      true
    end

    def stopped?
        not running?
    end

    def db
      ClassWrap[ @base_collection ]
    end

    def inspect
      "#<#{self.class}:#{self.hash.to_s(16)} #{running? ? 'running' : 'stopped'}>"
    end

    def xquery_service
      ClassWrap[ @base_collection.getService('XQueryService', '1.0') ]
    end

  end
end

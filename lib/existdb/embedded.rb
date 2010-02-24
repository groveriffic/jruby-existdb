module ExistDB
  class Embedded
    include Meta

    attr_accessor :username, :password, :url, :properties

    def initialize(*options)
      initialize_with_options(options, [:username, :password])
      yield self if block_given?

      @username ||= 'admin'
      @password ||= ''
      @properties ||= {'create-database' => 'true'}
      @url ||= "exist:///db"

      start
    end

    def start
      @impl = org.exist.xmldb.DatabaseImpl.new
      @properties.each{ |key, value| @impl.setProperty(key.to_s, value.to_s) }
      org.xmldb.api.DatabaseManager.registerDatabase(@impl)

      at_exit do
        stop
      end

      true
    end

    def stop
      database_instance_manager.shutdown
      true
    end

    def db
      ClassWrap[ base_collection ]
    end

    def inspect
      "#<#{self.class}:#{self.hash.to_s(16)}>"
    end

    def xquery
      ClassWrap[ base_collection.getService('XQueryService', '1.0') ]
    end

    private

    def base_collection
      @impl.getCollection(@url, @username, @password)
    end

    def database_instance_manager
      base_collection.getService('DatabaseInstanceManager', '1.0')
    end

    def collection_manager
      base_collection.getService('CollectionManager', '1.0')
    end

  end
end

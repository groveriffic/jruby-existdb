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

      @running = true
    end

    def running?
      @running
    end

    alias :started? :running? 

    def stop
      return false if stopped?
      @database_instance_manager.shutdown
      @running = false
      true
    end

    def stopped?
        not running?
    end

    def db
      raise InstanceNotRunning if stopped?
      ClassWrap[ @base_collection ]
    end

    def inspect
      "#<#{self.class}:#{self.hash.to_s(16)} #{running? ? 'running' : 'stopped'}>"
    end

    def xquery_service
      raise InstanceNotRunning if stopped?
      ClassWrap[ @base_collection.getService('XQueryService', '1.0') ]
    end

    # org.exist.storage.BrokerPool
    def broker_pool
      raise InstanceNotRunning if stopped?
      org.exist.storage.BrokerPool.getInstance(@impl.getName)
    end

    # org.exist.storage.txn.Txn
    def transaction # :yields: transaction
      raise InstanceNotRunning if stopped?
      mgr = broker_pool.getTransactionManager
      txn = mgr.beginTransaction
      begin
        yield txn
        mgr.commit(txn)
      rescue
        mgr.abort(txn)
        raise
      end
    end

    class InstanceNotRunning < Exception; end
  end

end

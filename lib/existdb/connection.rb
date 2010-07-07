module ExistDB
  class Connection
    java_import org.xmldb.api.DatabaseManager
    attr_accessor :username, :password, :url

    def initialize(options = {}, &block)
      @username = options[:username]
      @password = options[:password]
      @url = options[:url]
      self.instance_eval(&block) if block_given?
      @username ||= 'admin'
      @password ||= 'admin'
      @url ||= "xmldb:exist://localhost:8080/exist/xmlrpc/db" 

      @impl = org.exist.xmldb.DatabaseImpl.new()
      DatabaseManager.registerDatabase(@impl)

      @base_collection = DatabaseManager.getCollection(@url, @username, @password)
    end

    def db
      ClassWrap[ @base_collection ]
    end

    def inspect
      "#<#{self.class}:#{self.hash.to_s(16)} url: #{url}>"
    end

    def xquery_service
      ClassWrap[ @base_collection.getService('XQueryService', '1.0') ]
    end

    # org.exist.storage.BrokerPool
    def broker_pool
      org.exist.storage.BrokerPool.getInstance(@impl.getName)
    end

    # org.exist.storage.txn.Txn
    def transaction # :yields: transaction
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
  end
end

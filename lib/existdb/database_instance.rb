module ExistDB
    class DatabaseInstance
        import 'org.xmldb.api.DatabaseManager'
        import 'org.exist.xmldb.DatabaseImpl'
        
        attr_reader :handle

        def initialize(*opts)
            opts.each do |o|
                url = o[:url] if o[:url]
                username = o[:username] if o[:username]
                password = o[:password] if o[:password]
                properties = o[:properties] if o[:properties]
            end
            url ||= 'xmldb:exist:///db'
            username ||= 'admin'
            password ||= ''
            properties ||= {'create-database' => 'true'}

            database = DatabaseImpl.new
            properties.each do |key, value|
                database.setProperty(key.to_s, value.to_s)
            end
            DatabaseManager.registerDatabase(database)

            @handle = DatabaseManager.getCollection(url, username, password)

            if block_given?
                begin
                    yield db
                ensure
                    shutdown
                end
            else
                # Register at_exit hook
                at_exit do
                    shutdown
                end
            end
        end

        def shutdown
            manager.shutdown
        end

        def db
            ClassWrap[ @handle ]
        end

        def [](path)
            chunks = path.split('/', 3)
            if chunks[0] == '' and chunks[1] == 'db' then
                if chunks[2].nil? or chunks[2].empty? then
                    db
                else
                    db[ chunks[2] ]
                end
            end
        end

        def create_collection(path)
            ClassWrap[ collection_manager.createCollection(path) ]
        end

        def xquery
            ClassWrap[ @handle.getService('XQueryService', '1.0') ]
        end

        private

        def collection_manager
            @handle.getService('CollectionManager', '1.0')
        end

        def manager
            @handle.getService('DatabaseInstanceManager', '1.0')
        end

    end
end

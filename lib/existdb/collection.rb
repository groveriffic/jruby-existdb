module ExistDB
    class Collection

        extend ClassWrappingForwardable
        delegate_to_java :name, :path, :uri, :parent => :getParentCollection
        
        def initialize(java_obj)
            @obj = java_obj
        end

        def collections
            child_collection_names.map{|name|
                collection(name)
            }
        end

        def collection(name)
            Collection.new( @obj.getChildCollection(name) ) if child_collection_names.include?(name)
        end

        def resources
            resource_names.map{ |name|
                resource(name)
            }
        end

        def resource(name)
            Resource.new( @obj.getResource(name) ) if resource_names.include?(name)
        end

        # Supports relative paths including slashes
        # e.g. 'foo/bar/baz'
        # Wish I could figure out how to do absolute paths from here...
        def [](path)
            (myconcern, remainder) = path.split('/', 2)
            if myconcern.nil? or myconcern == '' then
                return nil
            elsif myconcern == '..' then
                target = parent
            else
                target = collection(myconcern) || resource(myconcern)
            end

            if target.nil? then
                return nil
            elsif remainder then
                return target[remainder]
            else
                return target
            end
        end

        def delete(resource = nil)
            if resource.nil? then
                collection_manager.removeCollection(@obj.uri)
            else
                @obj.removeResource( ClassUnwrap[ resource ] )
            end
            true
        end

        def xquery
            ClassWrap[ @obj.getService('XQueryService', '1.0') ]
        end

        def create_collection(path)
            ClassWrap[ collection_manager.createCollection( self.path + '/' + path ) ]
        end

        def store_url(url, name)
            url = url.to_s.gsub(/&(?!amp;)/, '&amp;')
            xquery.query("xmldb:store( '#{self.uri}', '#{name}', doc(#{url.inspect})  )")
        end

        def inspect
            "#<#{self.class}:0x#{self.hash.to_s(16)} name=#{self.name.inspect}>"
        end

        def child_collection_names
            @obj.getChildCollections.collect
        end

        def resource_names
            @obj.getResources.collect
        end

        private

        def collection_manager
            @obj.getService('CollectionManager','1.0')
        end

    end
end

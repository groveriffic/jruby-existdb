module ExistDB
    class ResourceSet

        include Enumerable
        extend ClassWrappingForwardable
        delegate_to_java(
            :size => :getSize,
            :[] => :getResource,
            :join => :getMembersAsResource,
            :add => :addResource
        )

        def initialize(java_obj)
            @obj = java_obj
        end

        def each
            for i in (0 .. (size - 1))
                yield self[i]
            end
        end

        class << self
            def [](*resources)
                set = new( org.exist.xmldb.MapResourceSet.new )
                resources.each do |resource|
                    set.add(resource)
                end
                return set
            end
        end

    end
end

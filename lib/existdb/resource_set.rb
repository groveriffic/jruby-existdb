module ExistDB
    class ResourceSet

        include Enumerable
        extend ClassWrappingForwardable
        delegate_to_java(
            :size => :getSize,
            :[] => :getResource
        )

        def initialize(java_obj)
            @obj = java_obj
        end

        def each
            for i in (0 .. (size - 1))
                yield self[i]
            end
        end

    end
end

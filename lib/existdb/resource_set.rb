module ExistDB
    class ResourceSet

        include Enumerable
        extend ClassWrappingForwardable
        delegate_to_java(
            :join => :getMembersAsResource,
            :add => :addResource
        )

        def initialize(java_obj)
            @obj = java_obj
        end

        def [](index, count = nil)
            if index.is_a?(Range) then
                raise ArgumentError if count
                return index.to_a.map{ |i| self[i] }
            else
                if count then
                    retval = Array.new
                    count.times do |i|
                        retval << self[ index + i - 1 ]
                    end
                    retval
                else
                    ClassWrap[ @obj.getResource(index) ]
                end
            end
        end

        def first(n = nil)
            if n then
                self[0..(n-1)]
            else
                self[0]
            end
        end

        def last(n = nil)
            if n then
                self[(0-n)..-1]
            else
                self[-1]
            end
        end

        def length
            @obj.getSize
        end
        alias :size :length

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

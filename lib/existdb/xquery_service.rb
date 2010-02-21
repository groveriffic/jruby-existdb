module ExistDB
    class XQueryService
        extend ClassWrappingForwardable
        delegate_to_java :compile, :dump, :query, :execute
        
        def initialize(java_obj)
            @obj = java_obj
        end

    end
end

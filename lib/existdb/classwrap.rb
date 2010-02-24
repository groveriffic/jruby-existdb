module ExistDB

    class ClassUnwrap
        class << self
            def [](obj)
                if obj.is_a?(Array) then
                    return obj.map{ |o| ClassUnwrap[o] }
                else
                    obj.instance_variable_get(:@obj) || obj
                end
            end
        end
    end
    
    class ClassWrap
        class << self
            def [](java_obj)
                return nil if java_obj.nil?
                if java_obj.is_a?(Fixnum) or java_obj.is_a?(String) then
                    return java_obj
                end
                klass = map[java_obj.class]
                if klass then
                    if klass.is_a?(Proc) then
                        return klass.call(java_obj)
                    else
                        return klass.new(java_obj)
                    end
                else
                    raise "I don't know how to wrap [#{java_obj.class}]"
                end
            end

            def map
                {
                    Java::OrgExistXmldb::LocalCollection => Collection,
                    Java::OrgExistXmldb::LocalXPathQueryService => XQueryService,
                    Java::OrgExistXmldb::LocalResourceSet => ResourceSet,
                    Java::OrgExistXmldb::LocalXMLResource => Resource::Xml,
                    Java::OrgExistXmldb::LocalBinaryResource => Resource::Binary,
                    Java::OrgExistXmldb::FullXmldbURI => Proc.new { |obj| obj.toString },
                    Java::JavaUtil::Date => Proc.new { |obj| Time.parse( obj.to_s ) },
                    Java::OrgExistXquery::PathExpr => Proc.new { |obj| obj }
                }
            end
        end
    end

    module ClassWrappingForwardable
        def delegate_to_java(*opts)
            opts.each do |opt|
                if opt.is_a?(Hash) then
                    opt.each do |to, from|
                        module_eval "
                            def #{to}(*opts)
                                ClassWrap[ @obj.#{from}( *ClassUnwrap[ opts ] ) ]
                            end
                        "
                    end
                else
                    module_eval "
                        def #{opt}(*opts)
                            ClassWrap[ @obj.#{opt}( *ClassUnwrap[ opts ] ) ]
                        end
                    "
                end
            end
        end
    end
end

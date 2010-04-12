module ExistDB
    module Dom
        
        # Inspired by Rails ActiveRecord
        # Because we cannot make assumptions about the structure of XML this must inspect the dom when descending into each node.
        # For large well structured documents a mapper pattern where the structure is defined in the class would be more efficient.

        class ActiveRecord

            module NodeArray
                def [](*opts)
                    raw = super
                    if raw.is_a?(Array) then
                        return raw.map{|obj| convert(obj) }
                    else
                        return convert(raw)
                    end
                end

                def each
                    super do |obj|
                        yield convert(obj)
                    end
                end
            end

            module Convertible
                private

                def convert(obj)
                    @cache ||= Hash.new
                    if @cache[obj] then
                        return @cache[obj]
                    else
                        if obj.getFirstChild.getNodeName == '' then
                            @cache[obj] = obj.getNodeValue
                        else
                            @cache[obj] = ActiveRecord.new(obj)
                        end
                        return @cache[obj]
                    end
                end
            end


            include org.w3c.dom.Node
            include Convertible

            def initialize(resource)
                @dom = resource.respond_to?(:dom) ? resource.dom : resource
                @children = Hash.new
                @raw = Hash.new
                @dom.getChildNodes.each do |child|
                    name = child.getNodeName.to_s.to_sym
                    next if respond_to?(name)
                    @raw[name] ||= Array.new
                    @raw[name] << child
                end

                @raw.each_key do |name|
                    if @raw[name].size > 1 then
                        @raw[name].extend(NodeArray, Convertible)
                        self.instance_eval %{
                            def #{name}
                                @raw[#{name.inspect}]
                            end
                        }
                    else
                        @raw[name] = @raw[name].first
                        self.instance_eval %{
                            def #{name}
                                convert( @raw[#{name.inspect}] )
                            end
                        }
                    end
                end

            end

        end
    end
end

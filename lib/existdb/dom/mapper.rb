
module ExistDB
    module Dom

        # Inspired by HappyMapper

        module Mapper
            def self.included(base)
                base.instance_variable_set("@attributes", Hash.new)
                base.instance_variable_set("@elements", Hash.new)
                base.extend ClassMethods
            end

            def initialize(resource)
                @dom = resource.respond_to?(:dom) ? resource.dom : resource
                @cache = Hash.new
            end

            def to_s
                if @dom then
                    w = java.io.StringWriter.new
                    x = org.exist.util.serializer.XMLWriter.new(w)
                    s = org.exist.util.serializer.DOMSerializer.new(w, java.util.Properties.new)
                    s.serialize(@dom)
                    w.flush
                    return w.toString
                end
            end

            private

            def get_element(tag_name)
                @cache[tag_name] ||= self.class.get_element(tag_name, @dom)
            end

            def get_elements(tag_name, klass)
                @cache[tag_name] ||= self.class.get_elements(tag_name, klass, @dom)
            end

            def get_attribute(tag_name)
                @cache[tag_name] ||= self.class.get_attribute(tag_name, @dom)
            end

            def set_element(tag_name, value)
                @cache.delete(tag_name)
                self.class.set_element(@dom, tag_name, value)
            end

            def set_attribute(tag_name, value)
                @cache.delete(tag_name)
                self.class.set_attribute(@dom, tag_name, value)
            end

            module ClassMethods

                def attribute(name, type = String, options = {})
                    a = Attribute.new(name, type, options)
                    @attributes ||= Hash.new
                    @attributes[a.tag] = a
                    self.class_eval %{
                        def #{a.method_name}
                            get_attribute(#{a.tag.inspect})
                        end
                        
                        def #{a.method_name}=(value)
                            set_attribute(#{a.tag.inspect}, value)
                        end
                    }
                end

                def attributes
                    @attributes.values
                end

                def element(name, type = String, options = {}, &block)
                    e = Element.new(name, type, options)
                    @elements ||= Hash.new
                    @elements[e.tag] = e

                    if (type.respond_to?(:is_dom_mapper?) and type.is_dom_mapper?) or block_given? then # Nested elements
                        if block_given? then # Anonymous Mapper Class
                            klass = self.class_eval %{
                                @@#{e.method_name}_klass = Class.new do
                                    include ExistDB::Dom::Mapper
                                end
                            }
                            klass.instance_eval &block
                        else
                            self.class_eval %{
                                @@#{e.method_name}_klass = #{type}
                            }
                        end
                        self.class_eval %{
                            def #{e.method_name}
                                get_elements(#{e.tag.inspect}, @@#{e.method_name}_klass)
                            end
                        }
                    else # No nested elements
                        self.class_eval %{
                            def #{e.method_name}
                                get_element(#{e.tag.inspect})
                            end
                            
                            def #{e.method_name}=(value)
                                set_element(#{e.tag.inspect}, value)
                            end
                        }
                    end
                end

                def elements
                    @elements.values
                end

                def get_element(tag_name, dom)
                    e = @elements[tag_name]
                    child = getFirstChildByTagName(dom, tag_name)
                    return e.type_cast( child.getNodeValue ) if child.respond_to?(:getNodeValue)
                    return nil
                end

                def get_elements(tag_name, klass, dom)
                    children = dom.getElementsByTagName(tag_name)
                    size = children.getLength
                    if size == 1 then
                        klass.new(children.item(0))
                    elsif size > 1 then
                        0..size.map{ |i| klass.new(children.item(i)) }
                    end
                end

                def get_attribute(tag_name, dom)
                    a = @attributes[tag_name]
                    value = dom.getAttributes.getNamedItem(tag_name).getValue rescue nil
                    a.type_cast( value )
                end

                def set_element(dom, tag_name, value)
                    parent = dom
                    node = getFirstChildByTagName(dom, tag_name)
                    
                    if node.nil? then
                        doc = parent.getOwnerDocument
                        node = doc.createElement( tag_name.to_s )
                        parent.appendChild(node)
                    end

                    child = node.getChildNodes.select{ |child| 
                        child.getNodeType == org.w3c.dom.Node.TEXT_NODE }.first
                    text = org.exist.dom.TextImpl.new( value.to_s.to_java_string )
                    if child then
                        ExistDB::Embedded.instance.transaction do |transaction|
                            text.setOwnerDocument( node.getOwnerDocument )
                            node.updateChild(transaction, child, text)
                        end
                    else
                        node.appendChild(text)
                    end
                    return value
                end
                
                def set_attribute(dom, tag_name, value)
                    attr = dom.getAttributes.getNamedItem(tag_name)
                    new_attr = org.exist.dom.AttrImpl.new(
                        org.exist.dom.QName.new( tag_name.to_s.to_java_string ),
                        value.to_s.to_java_string )
                    ExistDB::Embedded.instance.transaction do |transaction|
                        if attr then
                            new_attr.setOwnerDocument( dom.getOwnerDocument )
                            dom.updateChild(transaction, attr, new_attr)
                        else
                            dom.appendChild(new_attr)
                        end
                    end
                    return value
                end

                def tag(new_tag_name)
                    @tag_name = new_tag_name.to_s unless new_tag_name.nil? || new_tag_name.to_s.empty?
                end

                def tag_name
                    @tag_name ||= to_s.split('::').last.downcase
                end

                def parse(resource, options = {})

                    if options[:single] then
                        return new(resource)
                    else
                        xpath = options[:xpath]
                        xpath ||= "//#{options[:tag]}" if options[:tag]
                        xpath ||= "//#{options[:name]}" if options[:name]
                        xpath ||= "//#{tag_name}"

                        resource_set = resource.xquery(xpath)
                        return resource_set.map{ |res| new(res) }
                    end

                end

                def find(*options)
                    xql = XQLFactory::XQLFactory.new(*options)

                    if xql.node_xpath.nil? then
                        xql.node_xpath = "//#{tag_name}"
                    end

                    if xql.doc.is_a?(Resource::Xml) then
                        xql.doc.query(xql.xquery).map{ |res| new(res) }
                    elsif xql.doc.is_a?(ResourceSet) then
                        xql.doc.join.query(xql.xquery).map{ |res| new(res) }
                    elsif xql.doc.is_a?(String) and Embedded.instance.running?
                        Embedded.instance.xquery_service.query(xql.xquery).map{ |res| new(res) }
                    else
                        nil
                    end
                end

                def find_by_xquery(resource, query)
                    nodes = resource.xquery(query)
                    nodes.map{ |node| new(node) }
                end

                def is_dom_mapper?
                    true
                end

                private

                def getFirstChildByTagName(dom, tag_name)
                    dom.getChildNodes.each do |child|
                        next if not child.respond_to?(:getTagName) or child.getTagName != tag_name
                        return child
                        break
                    end
                    return nil
                end

            end

            class Boolean; end

            class Item
                attr_accessor :name, :type, :tag, :options, :method_name
                def initialize(name, type, o={})
                    self.name = name.to_s
                    self.method_name = self.name.tr('-','_')
                    self.type = type
                    self.tag = o[:tag] || name.to_s
                    self.options = { :single => true }.merge(o.merge(:name => self.name))

                    @xml_type = self.class.to_s.split('::').last.downcase
                end

                def type_cast(value, type = self.type)
                    begin
                        if type == String then value.to_s
                        elsif type == Float then value.to_f
                        elsif type == Time then
                            Time.parse(value.to_s) rescue Time.at(value.to_i)
                        elsif type == Date then Date.parse(value.to_s)
                        elsif type == DateTime then DateTime.parse(value.to_s)
                        elsif type == Boolean then
                            ['true','t','1','y','yes'].include?(value.to_s.downcase)
                        elsif type == Integer then
                            # ganked from datamapper, and happymapper
                            value_to_i = value.to_i
                            if value_to_i == 0 && value != '0'
                                value_to_s = value.to_s
                                begin
                                    Integer(value_to_s =~ /^(\d+)/ ? $1 : value_to_s)
                                rescue ArgumentError
                                    nil
                                end
                            else
                                value_to_i
                            end
                        else
                            value
                        end
                    rescue
                        value
                    end
                end
            
            end

            class Element < Item; end

            class Attribute < Item; end

        end

    end
end

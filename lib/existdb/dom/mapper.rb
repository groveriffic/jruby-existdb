
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

            private

            def get_element(tag_name)
                @cache[tag_name] ||= self.class.get_element(tag_name, @dom)
            end

            def get_attribute(tag_name)
                @cache[tag_name] ||= self.class.get_attribute(tag_name, @dom)
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
                    }
                end

                def attributes
                    @attributes.values
                end

                def element(name, type = String, options = {})
                    e = Element.new(name, type, options)
                    @elements ||= Hash.new
                    @elements[e.tag] = e
                    self.class_eval %{
                        def #{e.method_name}
                            get_element(#{e.tag.inspect})
                        end
                    }
                end

                def elements
                    @elements.values
                end

                def get_element(tag_name, dom)
                    e = @elements[tag_name]
                    dom.getChildNodes.each do |child|
                        next if not child.respond_to?(:getTagName) or child.getTagName != tag_name
                        return e.type_cast( child.getNodeValue )
                        break
                    end
                    return nil
                end

                def get_attribute(tag_name, dom)
                    a = @attributes[tag_name]
                    value = dom.getAttributes.getNamedItem(tag_name) rescue nil
                    a.type_cast( value )
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
                        xql.doc.xquery(xql.xquery).map{ |res| new(res) }
                    elsif xql.doc.is_a?(ResourceSet) then
                        xql.doc.join.xquery(xql.xquery).map{ |res| new(res) }
                    elsif xql.doc.is_a?(String) and Embedded.instance.running?
                        Embedded.instance.xquery_service.query(xql.xquery).map{ |res| new(res) }
                    else
                        nil
                    end
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

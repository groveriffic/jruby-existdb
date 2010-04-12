
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
                @cache[tag_name] ||= @dom.getElementsByTagName(tag_name).get(0).getNodeValue
            end
            
            module ClassMethods

                def attribute(name, type = String, options = {})
                    raise 'BOOOOMMM!'
                end

                def attributes
                    @attributes[to_s] || []
                end

                def element(name, type = String, options = {})
                    element = [name, type, options]
                    tag_name = options[:tag] || name
                    method_name = name.to_s.tr('-','_')

                    @elements[to_s] ||= []
                    @elements[to_s] << element
                    self.class_eval %{
                        def #{method_name}
                            get_element(#{tag_name.inspect})
                        end
                    }
                end

                def elements
                    @elements[to_s] || []
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
            end

            class Item
                def initialize(name, type, o={})
                    self.name = name.to_s
                    self.type = type
                    self.tag = o[:tag] || name.to_s
                    self.options = { :single => true }.merge(o.merge(:name => self.name))

                    @xml_type = self.class.to_s.split('::').last.downcase
                end
            end

            class Element < Item; end
            class Attribute < Item; end
        end

    end
end

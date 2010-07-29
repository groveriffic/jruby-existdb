module ExistDB
    module Resource
        
        class << self
            def new(*options)
                if options.size == 1 and not options.first.is_a?(Hash) then
                    obj = options.first
                    ClassWrap[obj]
                else
                    if options.any?{|opt| opt.is_a?(Hash) && ( opt[:xml] || opt[:type] == 'XMLResource' ) } then
                        Xml.new(*options)
                    elsif options.any?{|opt| opt.is_a?(Hash) && ( opt[:binary] || opt[:type] == 'BinaryResource' ) } then
                        Binary.new(*options)
                    end
                end
            end
        end

        class Base
            extend ClassWrappingForwardable
            delegate_to_java(
                :content= => :setContent,
                :content => :getContent,
                :length => :getContentLength,
                :created => :getCreationTime,
                :last_modified => :getLastModificationTime,
                :resource_type => :getResourceType,
                :parent => :getParentCollection,
                :name => :getId
            )
            alias :to_s :content
            alias :size :length

            def initialize(*opts)
                options = Hash.new
                if opts.size == 1 and not opts.first.is_a?(Hash) then
                    @obj = opts.first
                else
                    opts.each do |opt|
                        if opt.is_a?(Hash) then
                           options.merge!(opt)
                        end
                    end

                    collection = ClassUnwrap[ options[:parent] ]
                    data = nil
                    if options[:binary]
                        type = "BinaryResource"
                        data = options[:binary]
                    elsif options[:xml]
                        type = "XMLResource"
                        data = options[:xml]
                    else
                        type = options[:type]
                        data = options[:content]
                    end
                    type ||= "XMLResource"
                    
                    @obj = collection.createResource(options[:name], type)

                    self.content = data if data
                end

            end

            def inspect
                "#<#{self.class}:0x#{self.hash.to_s(16)} name=#{self.name.inspect}>"
            end

            def save
                collection = @obj.getParentCollection
                collection.storeResource( @obj )
                true
            end

            def delete
                parent.delete(self)
            end

            def path
                File.join(parent.path, @obj.getId)
            end

        end
    end
end

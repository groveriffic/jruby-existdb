module ExistDB
    module IndexFactory
        class << self
            def configure(*opts, &block)
                cfg = IndexFactory.new(*opts, &block)
                cfg.configure
            end
        end

        # Example:
        # ExistDB::IndexFactory.configure do
        #   collection '/db/PartList'
        #   range 'qtyOnHand' => Fixnum, 'qtyOnOrder' => Fixnum
        #   lucene '//part', 'name', 'description'
        # end

        class IndexFactory

            include Meta

            attr_writer :collection

            def initialize(*options, &block)
                initialize_with_options(options, [:collection])
                self.instance_eval(&block)
            end

            def to_s
                wrapper do
                    ranges.to_s + lucenes.to_s
                end
            end

            def range(*targets)
                @ranges ||= Array.new
                targets.each do |target|
                    if target.is_a?(Hash) then
                        target.each do |key, value|
                            tgt_name = key.to_s
                            tgt_type = tgt_name.index('/') ? 'path' : 'qname'
                            index_type = type_convert(value)
                            @ranges << %|<create #{tgt_type}="#{tgt_name}" type="#{index_type}"/>|
                        end
                    elsif target.respond_to?(:to_s) then
                        tgt_name = target.to_s
                        tgt_type = tgt_name.index('/') ? 'path' : 'qname'
                        @ranges << %|<create #{tgt_type}="#{tgt_name}"/>|
                    end
                end
            end

            def lucene(*targets)
                @lucenes ||= Array.new
                targets.each do |target|
                    if target.is_a?(Hash) then
                        target.each do |key, value|
                            tgt_name = key.to_s
                            tgt_type = tgt_name.index('/') ? 'path' : 'qname'
                            index_type = type_convert(value)
                            @lucenes << %|<text #{tgt_type}="#{tgt_name}" type="#{index_type}"/>|
                        end
                    elsif target.respond_to?(:to_s) then
                        tgt_name = target.to_s
                        tgt_type = tgt_name.index('/') ? 'path' : 'qname'
                        @lucenes << %|<text #{tgt_type}="#{tgt_name}"/>|
                    end
                end
            end

            def collection(col = nil)
                @collection = col if col
                return @collection
            end

            def configure
                raise "Specify a collection" unless @collection
                col = collection.create_collection(configuration_collection_name)
                res = Resource.new(:parent => col, :name => configuration_file, :xml => to_s)
            end

            private

            def ranges
                @ranges && @ranges.join('')
            end

            def lucenes
                if @lucenes then
                    "<lucene>#{ @lucenes.join('') }</lucene>"
                end
            end

            def wrapper
                %|<collection xmlns="http://exist-db.org/collection-config/1.0"><index>| +
                yield +
                %|</index></collection>|
            end

            def type_convert(data_type)
                data_type = data_type.to_s
                {
                    'String' => 'xs:string',
                    'Fixnum' => 'xs:int',
                    'Bignum' => 'xs:int',
                    'Numeric' => 'xs:int',
                    'Float' => 'xs:float'
                }[data_type]
            end

            def configuration_file
                'collection.xconf'
            end

            def configuration_collection_name
                "/db/system/config#{@collection}" if @collection
            end

        end
    end
end

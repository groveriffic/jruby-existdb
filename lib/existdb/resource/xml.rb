module ExistDB
    module Resource
        class Xml < Base

            def query(*opts)
                parent.xquery.query(self, *opts)
            end

            def xquery
                parent.xquery
            end

            def dom
                @obj.getContentAsDOM
            end

        end
    end
end

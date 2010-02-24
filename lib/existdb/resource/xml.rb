module ExistDB
    module Resource
        class Xml < Base

            def xquery(*opts)
                parent.xquery.query(self, *opts)
            end

            def compile(*opts)
                parent.xquery.compile(*opts)
            end

            def execute(*opts)
                parent.xquery.execute(self, *opts)
            end

        end
    end
end

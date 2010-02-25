module ExistDB
    module Resource
        class Binary < Base

            def content=(data)
                bytes = data.to_s.to_java_bytes
                @obj.setContent(bytes)
            end

            def content
                to_io.read
            end

            def to_io
                input_stream = @obj.getStreamContent
                return Java.java_to_ruby(org.jruby.RubyIO.new(JRuby.runtime, input_stream).java_object)
            end

        end
    end
end

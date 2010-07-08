require File.expand_path(File.dirname(__FILE__) + '/../lib/existdb')

require 'pp'
require 'test/unit'

class Test::Unit::TestCase
    private
        def fixture_path
            File.expand_path(File.dirname(__FILE__) + '/fixtures')
        end
end

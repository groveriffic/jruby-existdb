
require 'test_helper'

class ResourceSetTest < Test::Unit::TestCase
    include ExistDB

    def setup
        Embedded.instance.start
        @db = Embedded.instance.db
        @res = Resource.new(:xml => File.read( fixture_path + '/senate.xml'), :name => 'senate.xml', :parent => @db)
        @res.save
    end

    def teardown
        @res.delete
        Embedded.instance.stop
    end

    def test_resource_set
        set = @res.query('//member')

        assert set.is_a?(ResourceSet)

        assert_equal 99, set.length
        assert_equal 99, set.size

        assert_equal set.first.to_s, set[0].to_s
        assert_equal set.last.to_s, set[-1].to_s
        assert_equal 10, set.first(10).size
        assert_equal 10, set.last(10).size

    end
end

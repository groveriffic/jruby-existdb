require 'test_helper'

class EmbeddedTest < Test::Unit::TestCase
    
    include ExistDB

    def test_running_state
        assert_nothing_raised do
            Embedded.instance.start
            assert Embedded.instance.running? == true
            assert Embedded.instance.started? == true
            assert Embedded.instance.stopped? == false
            Embedded.instance.stop
            assert Embedded.instance.running? == false
            assert Embedded.instance.started? == false
            assert Embedded.instance.stopped? == true
        end
    end

    def test_get_collection
        assert_nothing_raised do
            Embedded.instance.start
            db = Embedded.instance.db
            assert_kind_of(Collection, db)
            Embedded.instance.stop
        end

        assert_raise Embedded::InstanceNotRunning do
            Embedded.instance.db.inspect
        end
    end
end

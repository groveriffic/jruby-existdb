
require 'test_helper'

class ConnectTest < Test::Unit::TestCase
    
    include ExistDB

    def test_connect
        db = nil
        assert_nothing_raised do
            conn = Connection.new 
            db = conn.db
            resources = conn.db.resources
        end
        assert db.is_a?(Collection)

    end
end

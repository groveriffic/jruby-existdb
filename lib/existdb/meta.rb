module ExistDB
  module Meta
    # Metaprogramming conviences

    def initialize_with_options(options, ordered_options)
      # Usage: 
      #  class MyClass
      #    include Meta
      #    attr_accessor :opt1, :opt2
      #    def initialize(*options)
      #      initialize_with_options(options, [:opt1, :opt2])
      #    end
      #  end
      #
      # obj = MyClass.new(:opt1 => 'foo', :opt2 => 'bar')
      # # OR
      # obj = MyClass.new('foo', 'bar')
      # # MyClass.new now accepts named or ordered params!
      named_or_ordered_options(options, ordered_options).each do |key, value|
        if key.is_a?(Symbol) or key.is_a?(String) then
          key = "#{key}=".to_sym
          self.send(key, value)
        end
      end
      
    end

    def named_or_ordered_options(options, ordered_options)
      hash = Hash.new
      options.each_with_index do |option, i|
        if option.is_a?(Hash) then
          hash.merge!(option)
        else
          key = ordered_options[i]
          hash[key] = option
        end
      end
      return hash
    end
  end
end

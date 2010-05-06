module ExistDB
  module XQLFactory

    class << self

      # Shorthand for ExistDB::XQLFactory::XQLFactory.new( options ).xquery

      def Build(*opts, &block)
        XQLFactory.new(*opts, &block).xquery
      end
    end

    # This is used by the XQLFactory for remapping nodes
    #
    # This could possibly be simplified by using XSLT if there was a Ruby DSL for XSLT
    #
    # The primary goal is to keep the barrier to entry low for rubyists who have limited XML experience
    class Path

      attr_reader :to_s, :to_a
      def initialize(path)
        if path.is_a?(String) then
          @to_s = path
          @to_a = path.split('/')
        elsif path.is_a?(Array) then
          @to_s = path.join('/')
          @to_a = path
        end
      end

      def name
        @to_a.last
      end

      def context
        @to_a[0..-2]
      end

      def <=>(path)
        to_a <=> path.to_a
      end

      def common(path)
        a = Array.new
        self.to_a.each_index do |i|
          if self.to_a[i].nil? or
          path.to_a[i].nil? or
          self.to_a[i] != path.to_a[i] then
            break
          else
            a << self.to_a[i]
          end
        end
        a << ''
        return Path.new(a)
      end

      def switch_context(path)
        output = String.new
        common_path = self.common(path)
        diff = self.context.size - common_path.context.size
        if diff > 0 then
          output << self.context.last(diff).reverse.map{ |node| "</#{node}>"}.join
        end
        diff = path.context.size - common_path.context.size
        if diff > 0 then
          output << path.context.last(diff).map{ |node| "<#{node}>"}.join
        end
        return output
      end

    end

    # This is an attempt to create a Ruby DSL for the Most Common XQuery use cases.
    class XQLFactory
      
      include Meta
      attr_accessor :start, :max, :doc, :node_xpath, :sort, :return_attributes, :return_tag, :node_remap, :search
      # Accepts Ordered or Named Parameters for any of the attr_accessors
      #
      # Ordered Options -- :doc, :start, :max, :sort
      #
      # E.g.
      #
      # <tt>
      # xql = XQLFactory.new("doc('http://example.com')", 5, 10, :node_xpath => '//a').xquery
      # </tt>
      #
      # Would create an XQuery statement to find the fifth through tenth links on example.com
      #
      # See also ExistDB::XQLFactory.Build as a shorthand way of calling this.

      def initialize(*options)
        initialize_with_options(options, [:doc, :start, :max, :sort])
        yield self if block_given?
      end

      def limit_statement
        if start or max then
          "let $scope := subsequence($scope, #{start || 1}, #{max || 'count($scope)'})\n"
        else
          ''
        end
      end

      def sort_statement
        if sort then
          if sort.is_a?(String) then
            "order by $node/#{sort}"
          elsif sort.is_a?(Hash) then
            "order by $node/#{sort.keys.first} #{sort_direction(sort.values.first)}"
          elsif sort.is_a?(Array) then
            "order by " + sort.map{ |h| "$node/#{h.keys.first} #{sort_direction(h.values.first)}" }.join(', ')
          end
        else
          ''
        end
      end

      def sort_direction(dir)
        dir = dir.to_s.downcase
        if %w|asc ascending|.include?(dir)
            return :ascending
        elsif %|desc descending|.include?(dir)
            return :descending
        else
            return :ascending
        end
      end

      def search_statement
        "[contains(*, #{ search.inspect })]" if search
      end

      def init_statement
        raise "doc attribute required" if doc.nil? or doc.to_s.empty?
        raise "node_xpath attribute required" if node_xpath.nil? or node_xpath.empty?
        "let $scope := for $node in #{doc if doc.is_a?(String)}#{node_xpath}#{search_statement} #{sort_statement} return $node\n"
      end

      def return_tag
        @return_tag || 'xml'
      end

      def return_tag=(tag)
        @return_tag = tag
      end

      def return_statement
        if return_attributes_statement.empty? and @return_tag.nil? then
          "return $scope"
        else
          "return <#{return_tag}#{return_attributes_statement}> { $scope } </#{return_tag}>"
        end
      end

      def return_attributes_statement
        return '' if return_attributes.nil? or return_attributes.empty?
        ' ' + return_attributes.keys.map{ |key|
          "#{key}=#{return_attributes[key].to_s.inspect}"
        }.join(' ')
      end

      def node_remap_statement
        return '' if node_remap.nil? or node_remap.empty?
        output = "let $scope := for $node in $scope return\n"
        current_context = Path.new('')
        node_remap.to_a.map{|a|
          a[1] = Path.new(a[1]); a 
        }.sort.each do |a|
          (src_path, dest_path) = a
          output << current_context.switch_context(dest_path)
          current_context = dest_path
          output << "<#{dest_path.name}>{ $node#{src_path} }</#{dest_path.name}>"
        end
        output << current_context.switch_context( Path.new('') ) 
        output << "\n"
        return output
      end

      def xquery
        init_statement + limit_statement + node_remap_statement + return_statement
      end
      
    end
  end
end

require 'json'
class PNode
  attr_reader :pid
  def initialize(pid)
    @pid = pid
    @children = {}
  end
  def add_child(cnode)
    @children[cnode.pid] = cnode
  end
  def children
    @children.values
  end
  def serialize
  	# memoize is only useful from the bottom up
  	@serial ||=
  	  begin
	    if @children.length > 0
	      @children.values.collect { |child|
	        child.serialize.collect { |path|
	          @pid + "/" + path
	        }
	      }.flatten
	    else
	      [@pid + "/"]
	    end
	  end
	@serial
  end
end

class Node
  include Comparable
  attr_reader :pid
  def initialize(pid)
    @pid = pid
    @parents = {}
    @leaf = true
  end
  def add_parent(cnode)
    @parents[cnode.pid] = cnode
  end
  def parents
    @parents.values
  end
  def add_child(cnode)
    @leaf = false
  end
  def children
    @children.values
  end
  def parents?
  	@parents.length > 0
  end
  def children?
  	!@leaf
  end
  def root?
  	@parents.length == 0
  end
  def leaf?
  	@leaf
  end
  def <=>(that)
  	self.pid <=> that.pid
  end
  def serialize(force=false)
  	# memoize is only useful from the bottom up
  	@serial = nil if force
  	@serial ||=
  	  begin
  	  	case @parents.length
  	  	when 0
  	  		[@pid + '/']
	    else
	    	result = {}
	        @parents.each { |key, node|
	            node.serialize.each { |path|
	                result[path + @pid + '/'] = true
	            }
	        }
	        result.keys
	    end
	  end
	@serial
  end
end

Result = Struct.new(:paths, :nodes)

def parse1(tuples)
	_children = []
    _nodes = {}
    tuples.each { |tuple|
      _p = tuple['parent'].sub('info:fedora/','')
      _c = tuple['child'].sub('info:fedora/','')
      _children << _c
      if not _nodes.has_key?(_p)
        _nodes[_p] = PNode.new(_p)
      end
      if not _nodes.has_key?(_c)
        _nodes[_c] = PNode.new(_c)
      end
      _nodes[_p].add_child( _nodes[_c])
    }
    _nodes.reject! {|key,node| _children.include? node.pid }
    _paths = []
    _nodes.each { |key,node|
      _paths.concat(node.serialize)
    }
    result = Result.new
    result.paths = _paths
    result.nodes = _children
    result
end

def parse2(tuples)
    _nodes = {}
    len = 'info:fedora/'.length
    tuples.each { |tuple|
      _p = tuple['parent'][len..tuple['parent'].length]
      _c = tuple['child'][len..tuple['child'].length]
     _parent = begin
	   if not _nodes.has_key?(_p)
	     _nodes[_p] = Node.new(_p)
	   else
	     _nodes[_p]     	
	   end     	
	 end
     _child = begin
	   if not _nodes.has_key?(_c)
	     _nodes[_c] = Node.new(_c)
	   else
	     _nodes[_c]
	   end     	
	 end
      _child.add_parent( _parent)
      _parent.add_child(_child)
    }
    _paths = []
    _nodes.each { |key,node|
      if node.leaf?
        _paths.concat(node.serialize)
      end
    }
    result = Result.new
    result.paths = _paths
    result.nodes = _nodes.keys # includes the root pid
    result
end

#b = Time.now
#result1 = parse1(JSON::parse(open('spec/fixtures/many_pc_tuples.json').read)['results'])
e1 = Time.now
result2 = parse2(JSON::parse(open('spec/fixtures/many_pc_tuples.json').read)['results'])
e2 = Time.now
path_missing = []
child_missing = []
# puts "method 1 times: #{e1 - b} method 2 time: #{e2 - e1}"
puts "method 2 time: #{e2 - e1}"
#puts "path diffs: #{result1.paths - result2.paths}"

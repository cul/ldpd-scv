require 'json'
class Node
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
end

Result = Struct.new(:paths, :children)

@tuples = JSON::parse(open('spec/fixtures/many_pc_tuples.json').read)['results']

def parse_as_nodes(tuples)
	_children = []
    _nodes = {}
    tuples.each { |tuple|
      _p = tuple["parent"].sub("info:fedora/","")
      _c = tuple["child"].sub("info:fedora/","")
      _children << _c
      if not _nodes.has_key?(_p)
        _nodes[_p] = Node.new(_p)
      end
      if not _nodes.has_key?(_c)
        _nodes[_c] = Node.new(_c)
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
    result.children = _children
    result
end

result = parse_as_nodes(@tuples)
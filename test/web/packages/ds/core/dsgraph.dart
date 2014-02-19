part of ds.core;

class GraphFilter extends dsFilter{
  dsGSearcher searcher;
  Function processor;
  dsGraph graph;
  dynamic _key;
  Completer _future;
  bool _all = false;

  GraphFilter.depthFirst(dsGraphNode processor(k,n,a)){
    this.searcher = new dsDepthFirst(this._filteringOneProcessor);
    this.processor = processor;
  }

  GraphFilter.breadthFirst(dsGraphNode processor(k,n,a)){
    this.searcher = new dsBreadthFirst(this._filteringOneProcessor);
    this.processor = processor;
  }
  
  GraphFilter use(dsGraph a){
	  this.graph = a;
	  return this;
  }
	 
  Future filter(dynamic k){
	 this._future = new Completer();
	  this._key = k;
	  this.searcher.search(this.graph).then((n){
      if(!this._future.isCompleted);
        //this._future.completeError(new Exception('Not Found'));
    });
    
	  return this._future.future;
  }
  
  Future filterAll(dynamic k){
 	  this._future = new Completer();
	  var it = this.graph.nodes.iterator, res = new List();
	  while(it.moveNext()){
		  if(it.current.data != k) continue;
		  res.add(it.current);
	  }
    (res.isEmpty && !this._future.isCompleted ? this._future.completeError(new Exception('Not Found!')) 
     : this._future.complete(res));
	  return this._future.future;
  }
  
  void _filteringOneProcessor(node,[arc,graph]){
  	  var n = this.processor(this._key,node,arc); 
      if(n != null){
        this._future.complete(n);
        graph.end();
      }
  }
  
  Future get finished => this._future.future;
}

class dsDepthFirst extends dsGSearcher{
	
	static create(d) => new dsDepthFirst(d);

	dsDepthFirst(void processor(dsGraphNode b,[dsGraphArc a,dsGSearcher g])): super(processor);
	
	Future search(dsAbstractGraph g){
		if(!this.isReady(g)) return new Future.value(null);
    	this.reset();
				
		var drained = this.processArcs(dsGraphArc.create(g.root.data,null),new Completer());
		g.clearMarks();
    return drained;
	}
	
	Future processArcs(dsGraphArc a,Completer d){
		if(a == null || a.node == null || this.interop){
      if(!d.isCompleted) d.complete(null);
      return d.future;
    }
		
		var n = a.node;
		this.processor(n,a,this);
		n.mark();
		var arc = n.arcs.iterator;
		while(arc.moveNext()){
			if(!arc.current.node.marked) 
				this.processArcs(arc.current,d);
		}
    if(!d.isCompleted) d.complete(null);
    return d.future;
	}


}

class dsLimitedDepthFirst extends dsDepthFirst{
    num depth = -1;

    static create(d) => new dsLimitedDepthFirst(d);

    dsLimitedDepthFirst(d):super(d);
    
    Future search(dsAbstractGraph g,[num depth]){
      this.depth = ((depth != null && depth != 0) ? depth : -1);
      return super.search(g);
    }

    Future  processArcs(dsGraphArc a,Completer d){
      if(this.depth == 0 || this.interop){
        if(!d.isCompleted) d.complete(null);
        return d.future;
      }
      
      if(this.depth != -1) this.depth -= 1;
      return super.processArcs(a,d);
    }
}


class dsLimitedBreadthFirst extends dsBreadthFirst{
    num depth = -1;

    static create(d) => new dsLimitedBreadthFirst(d);
	
    dsLimitedBreadthFirst(void processor(dsGraphNode b,[dsGraphArc a,dsGSearcher search])): super(processor);
    
    Future search(dsAbstractGraph g,[num depth]){
      if(!this.isReady(g)) return;
    	this.reset();
      this.depth = ((depth != null && depth != 0) ? depth : -1);

      var future = this.processArcs(dsGraphArc.create(g.root.data,null));
      g.clearMarks();
      return future;
      
    }
    
    Future processArcs(dsGraphArc a){
      var drained = new Completer();
      if(a == null || a.node == null || this.interop){
        drained.complete(null);
        return drained.future;
      }
      if(this.depth == 0){ this.depth = -1; return; }
      
      var queue = new Queue();
      queue.add(a);
      queue.first.node.mark();
      while(queue.isNotEmpty){
        if(this.depth == 0 || this.interop){
          this.reset();
          break;
        }
        this.processor(queue.first.node,queue.first,this);
        var arc = queue.first.node.arcs.iterator;
        while(arc.moveNext()){
          if(!arc.current.node.marked){
            queue.add(arc.current);
            arc.current.node.mark();
          }
        }
        queue.removeFirst();
        this.depth -= 1;
      }
      drained.complete(null);
      return drained.future;
    }

}

class dsBreadthFirst extends dsGSearcher{

	static create(d) => new dsBreadthFirst(d);
	
	dsBreadthFirst(void processor(dsGraphNode b,[dsGraphArc a,dsGSearcher search])): super(processor);
	
	Future search(dsAbstractGraph g){
		if(!this.isReady(g)) return;
    this.reset();
				
		var future = this.processArcs(dsGraphArc.create(g.root.data,null));
		g.clearMarks();
    return future;
		
	}
	
	Future processArcs(dsGraphArc a){
    var drained = new Completer();
		if(a == null || a.node == null || this.interop){
      drained.complete(null);
      return drained.future;
    }
		
		var queue = new Queue();
		queue.add(a);
		queue.first.node.mark();
		while(queue.isNotEmpty){
      	if(this.interop){
        this.reset();
        break;
      }
			this.processor(queue.first.node,queue.first,this);
			var arc = queue.first.node.arcs.iterator;
			while(arc.moveNext()){
				if(!arc.current.node.marked){
					queue.add(arc.current);
					arc.current.node.mark();
				}
			}
			queue.removeFirst();
		}
    drained.complete(null);
    return drained.future;
	}


}

class dsGraph<T,M> extends dsAbstractGraph<T,M>{
    
    dynamic git;

    static create() => new dsGraph<T,M>();

    dsGraph(): super(){
      this.nodes = new dsList<dsGNode<T,M>>();
      this.git = this.nodes.iterator;
    }
	
    dynamic findBy(Function n){
      var it = this.nodes.iterator;
      while(it.moveNext()){
        if(n(it.current)) {
          return it.current;
          break;
        }
      }
      return null;
    }
	
    dynamic find(dynamic data){
      if(data is dsGraphNode) return this.git.get(data.data);
      return this.git.get(data);
    }
	
    dsGraphNode add(dynamic data){
      if(data is dsGraphNode) return this.nodes.append(data).data;
      return this.nodes.append(dsGraphNode.create(data)).data;
    }
    
    void bind(dsGraphNode<T,M> from,dsGraphNode<T,M> to,dynamic weight){
      from.addArc(to,weight);
      if(!this.git.has(from)) this.add(from);
      if(!this.git.has(to)) this.add(to);
    }
  
    void unbind(dsGraphNode<T,M> from,dsGraphNode<T,M> to){
      from.removeArc(to);
      if(!this.git.has(from)) this.add(from);
      if(!this.git.has(to)) this.add(to);
    }

    void cascade(Function n,[Function m]){
       this.nodes.iterator.cascade(n,m);
    }

    dynamic eject(dsGraphNode<T,M> to){
      var handle = this.nodes.iterator;
      while(handle.moveNext()){
        handle.current.removeArc(to);
      }
      return this.git.remove(to);
    }
	
    void clearMarks(){
      while(this.git.moveNext()){
        this.git.current.unmark();
      }
    }
    
    String toString(){
      var map = new StringBuffer();
      map.write("<GraphMap:\n");
      while(this.git.moveNext()){
        map.write('<Edge:<');
        map.write(this.git.current.printArcs());
        map.write('>>');
      }
      map.write('>');
      return map.toString();
    }
    
    void flush() => this.nodes.free();
    
    dsGraphNode get first => this.nodes.root.data;
    dsGraphNode get last => this.nodes.tail.data;
    bool get isEmpty => this.nodes.isEmpty;
    int get size => this.nodes.size;
}

class dsGraphArc<T> extends dsGArc<dsGraphNode,T>{
	
	static create(n,w){
		return new dsGraphArc(n,w);
	}
	
	dsGraphArc(node,weight) : super(node,weight);

  String toString(){
    return "Arc: Node data ${this.node.data}, Weight: ${this.weight}";
  }
}

class dsGraphNode<T,M> extends dsGNode<T,M>{
	var _dit;
  	bool isUniq = true;
	
	static create(n,{bool unique: true}){
		return new dsGraphNode(n,unique: unique);
	}
	
	dsGraphNode(data,{bool unique: true}): super(data){
		this.arcs = new dsList<dsGraphArc<M>>();
		this._dit = this.arcs.iterator;
    this.isUniq = unique;
	}
	
	void addArc(dsGraphNode a,dynamic n){
		if(!this.isUniq) { 
      this.arcs.append(new dsGraphArc(a,n));
      return;
    }
    this.probe(a,(m){
      if(m == null) return this.arcs.append(new dsGraphArc(a,n));
    });
	}
	
	dsGraphArc findArc(dsGraphNode n){
		return this.arcFinder(n,(m){
			return m;
		});
	}
	
	dsGraphArc removeArc(dsGraphNode n){
		return this.arcFinder(n,(m){
      this._dit.remove(m);
      m.node.removeArc(this);
			return m;
		});
		
	}
	
	dsGraphArc removeAllArch(dsGraphNode n){
		return this.arcFinder(n,(m){
			return this._dit.remove(m,all:true);
		});
	}
	
	bool removeAllArchs(){
		return this.arcs.removeAll();
	}
		
	bool arcExists(dsGraphNode n,[Function m]){
		return this.arcFinder(n,(m){
			return true;
		});
	}
	
   dsGraphArc arcFinder(dsGraphNode n,Function callback){
    	this.probe(n,(m){
      		if(m != null) return callback(m);
    	});
   }

   dynamic probe(dsGraphNode n,Function callback){
     var itr = this.arcs.iterator;
		  while(itr.moveNext()){
			 if(!itr.current.node.compare(n)) continue;
			 return callback(itr.current);
			 break;
		  }
     return callback(null);
   }

   dynamic probeWith(dsGraphNode n,Function callback,Function run){
     var itr = this.arcs.iterator;
      while(itr.moveNext()){
       var find = callback(it,n);
       if(find == null) continue;
       return find;
       break;
      }
     return callback(null);
   }
   
   String printArcs(){
     var buffer = new StringBuffer();
     buffer.write('Node: ${this.data} with Arcs: ${this.arcs.size}');
     buffer.write('\n');
     while(this._dit.moveNext()){
      buffer.write("<");
      buffer.write(this._dit.current.toString());
      buffer.write('>\n');
     }
     return buffer.toString();
   }
}

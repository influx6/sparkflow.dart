part of ds.core;

class Counter{
  num _count = 0;
  dynamic handler;
  
  Counter(this.handler);
  
  num get counter => _count;
  
  void tick(){
    _count += 1;
  }
  
  void untick(){
    _count -= 1;
  }
  
  void detonate(){
    _count = 0;
  }
  
  String toString(){
    return "Counter: "+this.counter.toString();
  }
}
  
class Comparable{
  bool compare(dynamic d);
}

class dsImpl {
	
	void addAll();
	void add();
	void free();
	void append();
	void prepend();
	void appendOn(dsNode n,dsNode m);
	void prependOn(dsNode n,dsNode m);
	dynamic get root;
	bool get isEmpty;
	
}

class dsSearcher{
	Future process(DS g);
}

class dsIteratorHelpers{
	void reset();
}
	
class dsIteratorImpl{
	void moveNext();
	dynamic get current;	
}

class DS implements dsImpl{
	bool marked = false;
	Counter bomb;
	
	DS(){ bomb = new Counter(this); }
	
	void mark(){ this.marked = true; }
	void unmark(){ this.marked = false; }
	
	void incCounter(){ bomb.tick(); }
	void decCounter(){ bomb.untick(); }
	void resetCounter(){ bomb.detonate(); }
	
	bool get isDs => true;
}

abstract class dsFilter{
	void use(dsAbstractGraph g);
	void filter(dynamic g);
	Future filterAll(dynamic a);
}

abstract class dsAbstractNode<T> implements Comparable{
	dsAbstractNode<T> left;
	dsAbstractNode<T> right;
	T data;
	bool _mark = false;
	
	void mark(){ this._mark = true; }
	void unmark(){ this._mark = false; }
	bool get marked => this._mark == true;
	bool get isFree => (data == null);
	
	String toString(){
		return this.data.toString();
	}
	
	bool compare(dsAbstractNode<T> a){
		return (a.data == this.data);
	}
	
	// sets data to null
	void free(){
		this.data = null;
	}
	
}

abstract class dsAbstractList<T> extends DS implements Comparable{
	dsAbstractNode<T> head;
	dsAbstractNode<T> tail;
	int maxSize = null;
	
	int get size => this.bomb.counter; 
	bool get isEmpty => (this.head == null && this.tail == null);
	
	dsAbstractIterator get iterator;	
	
	void setMax(int m){
	 this.maxSize  = m;  
	}
	
	void nullify(){
                this.head = this.tail = null;
                this.bomb.detonate();
        }
	
	bool isDense(){
	    if(this.maxSize == null) return false;
	    return this.size >= this.maxSize;
	}
}

abstract class dsTreeNode<T> extends dsAbstractNode<T>{
	dsTreeNode<T> left;
	dsTreeNode<T> right;
	dsTreeNode<T> root;
}

abstract class dsGSearcher implements dsSearcher{
	dsAbstractNode root;
	Function processor;
  bool _end = false;
	
	dsGSearcher(void processor(dsGNode b,[dsGArc a,dsGSearcher s])){
		this.processor = processor;
	}
	
	Future search(dsAbstractGraph g);
	Future processArcs(dsGraphArc a);
	
	bool isReady(dsAbstractGraph g){
	 	if(g.nodes.isEmpty || g.root == null) return false;
		return true;
	}

  void end(){
    this._end = true;
  }
  
  void reset(){
     this._end = false;
  }
  
  bool get interop => !!this._end;
}
	
abstract class dsGArc<N,T> implements Comparable{
	N node;
	T weight;
	
	dsGArc(this.node,this.weight);
	
	String toString(){
		return "NodeData:${this.node.data} Weight:${this.weight}";
	}
	
	bool compare(dsGArc a){
		if(this.node.compare(a.node) && this.weight == a.weight) return true;
		return a;
	}
}

abstract class dsGNode<T,M> extends dsAbstractNode<T> implements Comparable{
	dsAbstractList<dsGArc<dsGNode,M>> arcs;
	T data;
	
	dsGNode(this.data);
	
	void addArc(dsGNode a,dynamic n);
	dsGNode find(dsGNode n);
	bool arcExists(dsGNode n);
	dsGArc arcFinder(dsGNode n,Function callback);
	
	String toString(){
		return "data:${this.data}";
	}
	
	bool compare(dsGNode a){
		if(a.data == this.data) return true;
		return false;
	}
	
}

abstract class dsAbstractGraph<T,M> extends DS implements Comparable{
	dsAbstractList<dsGNode<T,M>> nodes;
	
	static create(){
		return new dsAbstractGraph<T,M>();
	}
	
	dynamic get size{
		return nodes.size;
	}
		
	dsAbstractNode get root{
		return this.nodes.root;
	}

  dsGraphNode add();
  void bind();
  void unbind();
  void eject();

}
		

abstract class dsAbstractIterator implements dsIteratorImpl,dsIteratorHelpers{
	static const int _uninit = 0;
	static const int _movin = 1;
	static const int _done = 2;
	int _state = 0;
	Counter counter;
	dsAbstractNode node;
	DS ds;
		
	dsAbstractIterator(this.ds){ counter = new Counter(this); }
  
  //allows creation of a iterator without a constructor initialized list to iterator on
  //allowing the list to be set later using the Iterator.ds = list; format
	dsAbstractIterator.Shell(){ counter = new Counter(this); }

	dsAbstractIterator createIterator(n);
	
	num get size{
		return this.ds.size;
	}
	
	String  get state{
		if(_state == _uninit) return "State::UnInitialized!";
		if(_state == _movin) return "State:Movable!";
		if(_state == _done) return "State::Done!";
	}
	
	dynamic get currentNode{
		if(this.node == null) return null;
		return this.node;	
	}
		
	dynamic get current{
		if(this.node == null) return null;
		return this.node.data;
	}
	
	bool move(Function init,Function change,Function reset){
		if(_state == _done){ reset(); this.reset(); }
		if(_state == _uninit){
			if(!init()) return false;
			_state = _movin;
		}
		else if(_state == _movin){
			if(!change()){
				_state = _done; 
				return false;
			};
		}
		
		this.counter.tick();
		return true;
	}
	
	bool moveNext([Function n]){
		return this.move((){
			if(this.ds.root == null) return false;
			this.node = this.ds.root;
			return true;
		},(){
			this.node = this.node.right;				
			if(this.node == this.ds.root || this.node == null || this.node.right == null) return false;
			return true;
		},(){
			if(n != null) n();
			return true;
		});
	}
	
	bool movePrevious([n]){
		return this.move((){
			if(this.ds.root == null) return false;
			this.node = this.ds.tail;
			return true;
		},(){
			this.node = this.node.left;				
			if(this.ds.tail == this.node || this.node == null || this.node.left == null) return false;
			return true;
		},(){
			if(n != null) n();
			return true;	
		});
	}
		
	void reset(){
		this.node = null;
		_state = _uninit;
		this.counter.detonate();
	}
	
	void detonate(){
		this.reset();
		this.ds = null;
	}
	
}

part of ds.core;

class dsList<T> extends dsAbstractList{
	dsListIterator _it;
	
  static create([n]){
	if(n != null && n is List) return new dsList.from(n);
    return new dsList();
  }
	
  factory dsList.fromDS(dsList data){
    return data.clone();
  }

  factory dsList.from(List data){
    var newlist = new dsList();
		data.forEach((n){ newlist.append(n); });
    return newlist;
  }

  dsList(){
	 this._it = dsListIterator.create(this);
  }
	
  dsNode add(T d) => this.append(d);

	dsNode append(T d){
		if(this.isEmpty){ 
	      this.head = this.tail = dsNode.create(d); 
	      this.incCounter();
	      return this.tail;
	  }
		var tail = this.tail;
		var left = tail.left;
		var right = tail.right;
		
		this.tail = dsNode.create(d);
		this.tail.right = this.head;
		this.tail.left = tail;
		
		if(tail != null) tail.right = this.tail;		
		this.head.left = this.tail;
		
		this.incCounter();
	    return this.tail;
	}
	
	dsNode prepend(T d){
		if(this.isEmpty){ 
      this.head = this.tail = dsNode.create(d); 
      this.incCounter();
      return this.head;
    }
		var head = this.head;
		var left = head.left;
		var right = head.right;
		
		this.head = dsNode.create(d);
		this.head.right = head;
		this.head.left = this.tail;
		
		head.left = this.head;
		this.incCounter();
    return this.head;
	}
	
	dynamic removeHead(){
    if(this.isEmpty) return this.nullify();
    
	  if(this.head == this.tail){
		  var cur = this.root;
		  cur.nullLinks();
		  this.nullify();
		  return cur;
	  }
	  
    var current = this.root;
    var left = current.left;
    var right = current.right;

    if(left == null && right == null){
      this.nullify();
      return current;
    }
    
    this.head = right;
    this.head.left = left;
    
    if(left != null) left.right = this.head;

    current.nullLinks();

		this.decCounter();
		return current;
	}
	
	dynamic removeTail(){
    if(this.isEmpty) 
      return this.nullify();

	  if(this.tail == this.head){
		  var cur = this.tail;
		  cur.nullLinks();
		  this.nullify();
		  return cur;
	  }
		
    var current = this.tail;
    var left = current.left;
    var right = current.right;

    if(left == null && right == null){
      this.nullify();
      return current;
    }
    
    this.tail = left;
    this.tail.right = right;
    
    if(right != null) right.left = this.tail;

		current.nullLinks();
		
		this.decCounter();
		return current;	
	}
	
	void removeAll(){
    if(this.isEmpty) return;
	  this.free();
	  this.head = this.tail = null;
	}


	
	void free(){ 
    if(this.isEmpty) return;
		this.head.freeCascade();	
		this.head.unmarkCascade();
    this.head = this.tail = null;
    this.bomb.detonate();
	}

	void clear(){
		this.removeAll();
	}

	dsList clone(){
	    var cloned = new dsList();
	    var itr = this.iterator;
	    while(itr.moveNext()){
	      clone.append(itr.current);
	    }
	    return cloned;
	}
  
	String toString(){
	    var buffer = new StringBuffer(),
	    it = this.iterator;
	    buffer.write("List::Contents:");
	    while(it.moveNext()) buffer.write(it.current);
	    return buffer.toString();
	}

	dsNode get root => this.head;
	dsListIterator get iterator => dsListIterator.create(this);
}

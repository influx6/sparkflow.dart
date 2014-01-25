part of ds.core;

class dsIterator extends dsAbstractIterator{
	
	dsIterator(ds): super(ds);
	dsIterator.Shell(): super.Shell();

	bool contains(dynamic n,[bool m(h,j)]){
		return this.has(n,m);
	}

	bool has(dynamic n,[bool m(h,j)]){
        if(this.ds.isEmpty) return false;
		var self = this.ds.iterator;
		while(self.moveNext()){
		  if(m == null && self.current != n) continue;
	      if(m != null && !m(self,n)) continue;
	      if(m != null && !!m(self,n)) return true;
	      return true;
	      break;
		}
		return false;
	}

	bool compare(dsIterator l,[bool m(h,j)]){
        if(this.ds.isEmpty) return null;
		if(this.size != l.size) return false;
		num matchCount = 0;
		var me = this.ds.iterator;
		
		while(l.moveNext()){
			if(me.has(l.current,m)) matchCount += 1;
		}
		
		if(matchCount == me.size) return true;
		return false;
	}
	
	dynamic get(dynamic n,[bool m(h,j)]){
      if(this.ds.isEmpty) return null;
		var self = this.ds.iterator;
		while(self.moveNext()){
      if(m == null && self.current != n) continue;
      if(m != null && !m(self,n)) continue;
      if(m != null && !!m(self,n)) return self.currentNode;
      return self.currenNode;
			break;
		}
		return;
	}
	
	List getAll(dynamic n,[bool m(h,j)]){
      if(this.ds.isEmpty) return [];
		var self = this.ds.iterator,res = new List();
		while(self.moveNext()){
		  if(m == null && self.current != n) continue;
		  if(m != null && !m(self,n)) continue;
	      if(m != null && !!m(self,n)) res.add(self.currentNode);
	      else res.add(self.currentNode);
		}
		return res;
	}
	

	void cascade(Function n,[Function complete]){
		if(this.ds.isEmpty) return;
		var self = this.ds.iterator;
		while(self.moveNext()) n(self);
		if(complete != null) complete(self);
	}
}

class dsListIterator extends dsIterator{
	
	static create(l){ return new dsListIterator(l); }
	dsListIterator(dsAbstractList l): super(l);
	
	dsListIterator createIterator(dsAbstractList l){
		return dsListIterator.create(l);
	}
	
	dynamic remove(dynamic l,[bool all,bool m(i,n)]){
		var steps = dsListIterator.create(this.ds);
		var res;
		
		while(steps.moveNext()){
      		if(m == null && steps.current != l) continue;
      		if(m != null && !m(steps,l)) continue;
      		if((m != null && !!m(steps,l)) || steps.current == l){
        
	        res = steps.currentNode;
	        var right = res.right;
	        var left = res.left;

	        if(right != null) left.right = right;
	        if(left != null) right.left = left;
	        if(steps.ds.head == res) steps.ds.head = right;
	        if(steps.ds.tail == res) steps.ds.tail = left;
	        
	        res.right = res.left = null;
	        if(all != null && all == true) res.free();
	        steps.ds.decCounter(); 
	        return res;
	        if(all != null || all == false) break;
	      }
		}
		
		steps.detonate();
	}
}

class dsSkipIterator extends dsIterator{
	dsIterator _it;
	num _skipCount;
	num _count;
	
	static create(ds,c){
		return new dsSkipIterator(ds,c);
	}
		
	dsSkipIterator(ds,count): super(ds){
		this._skipCount = this._count = count;
		_it = new dsIterator(ds);
	}
	
	bool moveNext([n]){
		for(var i =0; i < _skipCount; i++) this._it.moveNext();
		_skipCount = 0;
		return this._it.moveNext((){ _skipCount = _count; });
	}
	
	dynamic get current{
		return this._it.current;
	}
	
}

class dsSelectIterator extends dsIterator{
	final dsList phantom = new dsList();
	dsNode from;
	
  static create(dsNode m) => new dsSelectIterator(m);

	dsSelectIterator(this.from): super.Shell(){
    phantom.head = this.from;
    this.ds = phantom;
  }
  
  bool moveNext([n]){
    if(this.from == null || this.from.data == null) return false;
    return super.moveNext(n);
  }

  bool movePrevious([n]){
    if(this.from == null || this.from.data == null) return false;
    return super.movePrevious(n);
  }
}

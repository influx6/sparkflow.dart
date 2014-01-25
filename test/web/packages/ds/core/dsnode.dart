part of ds.core;


class dsNode<T> extends dsAbstractNode<T> implements Comparable{
	dsNode<T> left;
	dsNode<T> right;
	
	static create(dynamic data,{left: null,right:null}){
		return new dsNode(data,l:left,r:right);
	}
	
	dsNode(dynamic d,{dsNode l:null,dsNode r:null}){
		this.data = d;
		if(l != null) left = l;
		if(r != null) right = r;
	}
	
	void nullLinks(){
		this.left = this.right = null;
	}
	
	// this sends a all nodes linked to this node to set their data to 
	//null by calling the nodes free() method internal
	void freeCascade(){
		this.free();
		if(this.left != null && !this.left.isFree) this.left.freeCascade();
		if(this.right != null && !this.right.isFree) this.right.freeCascade();
	}
	
	void unmarkCascade(){
		this.unmark();
		if(this.left != null && this.left.marked) this.left.unmarkCascade();
		if(this.right != null && this.right.marked) this.right.unmarkCascade();
	}
	

}





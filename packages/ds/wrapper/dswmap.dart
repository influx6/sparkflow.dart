part of ds.wrapper;

class dsMapStorage<T,K> extends dsWAbstract<Map<T,K>,T,K>{
	
	static create(){
		return new dsMapStorage();
	}
	
	dsMapStorage(){
		store = new Map<T,K>();
	}
	
	dynamic get(T t){
		return this.store[t];
	}
	
	void set(T t,K k){
		this.store[t]=k;
	}
	
	void add(T t,K k){
		this.set(t,k);
	}
		
	K delete(T t){
		var n = this.get(t);
		this.store.remove(t);
		return n; 
	}
	
	bool has(T t,[K k] ){
		if(k == null) if(this.store.containsKey(t)) return true;		
		if(k != null) if(this.store.containsKey(t) && this.store[t] == k) return true;
		return false;
	}
	
}
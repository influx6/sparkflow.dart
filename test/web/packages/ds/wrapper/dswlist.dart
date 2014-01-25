part of ds.wrapper;


class dsListStorage<K> extends dsWAbstract<List,num,K>{
	
	dsListStorage(num maxSize){
		this.store = new List<K>(maxSize);
	}
	
	K get(num t){
		this.store[t];
	}
	
	void set(num t,K k){
		this.store[t] = k;
	}
	
	void add(K k){
		return this.store.add(k);	
	}
	
	void push(K k){
		this.add(k);
	}
	
	K delete(num b){
		var n = this.get(b);
		this.store.removeAt(b);
		return n;
	}
	
	bool has(dynamic t,[k]){
		if(this.store.index(t) != -1) return true;		
		return false;
	}

	
}
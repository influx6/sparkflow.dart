part of ds.wrapper;

class dsWImpl{
	dynamic get(dynamic n);
	void set(dynamic k,dynamic t);
	dynamic delete(dynamic n);
	has(dynamic n,[dynamic v]);
}

class dsWAbstract<V,T,K> extends dsStorage implements dsWImpl{
	V store;
	Mirror _stored;
	
	dynamic noSuchMethod(Invocation n){
		if(this._stored == null) this._stored = reflect(store);
		this._stored.delegate(n);
	}
	
	String toString(){
		return this.store.toString();
	}
}
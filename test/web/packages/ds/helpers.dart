part of ds;

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
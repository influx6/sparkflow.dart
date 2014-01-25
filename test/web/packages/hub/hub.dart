library hub;

import 'dart:mirrors';
import 'dart:math' as math;
import 'dart:async';


abstract class Comparable{
  bool compare(dynamic d);
}

class Transformable{
  Function _transformer;
  dynamic _bind;

  static create(Function n) => new Transformable(n);

  Transformable(Function n){
    this._transformer = n;
  }

  void changeFn(Function n){
    this._transformer = n;
  }

  void change(dynamic n){
    this._bind = n;
  }

  dynamic out(dynamic j){
    if(this._bind == null) return null;
    return this._transformer(this._bind,j);
  }
}


abstract class Injector<T>{
  final consumer = Hub.createDistributor('Injector');
  Function condition,modifier;
  dynamic target;
  
  Injector(this.target,this.condition,this.modifier);
  
  void on(Function n){ this.consumer.on(n); }
  
  void inject(){}
  
  void push(T n){}
}

class ListInjector<T> extends Injector<T>{
  
  static create(n,[k,m]) => new ListInjector(n,k,m);

  ListInjector(bool c(m,n),h,[n]): super(h,(target,controller){ 
    if(!!c(target,controller)) return controller.inject(); 
  },(n == null ? (i){ return i; } : n));
  
  void inject(){
    this.consumer.emit(this.modifier(this.target));
  }
  
  void push(T n){
    this.target.add(n);
    this.condition(this.target,this);
  }
}

class LengthInjector<T> extends ListInjector<T>{
    int length;
    
    static create(n,[fn,fns]) => new LengthInjector(n,fn,fns);

    LengthInjector(this.length,[fn,fns]): super((fn != null ? fn : (tg,ct){
       if(tg.length >= ct.length) return true;return false;
    }),[],( fns != null ? fns : (list){
      var clone = new List.from(list);
      list.clear();
      return clone;
    }));
    
}

class PositionInjector<T> extends  ListInjector<T>{
  int length;
    
    static create(n,[fn,fns]) => new PositionInjector(n,fn,fns);
    
    PositionInjector(this.length,[fn,fns]): super((fn != null ? fn : (tg,ct){
      if(tg.length >= ct.length) return true; return false;
    }),Hub.createSparceList(),(fns != null ? fns : (target){
        var list =  target.sorted();
        target.clear();
        return list;
    }));
    
    @override
    void push(int pos,T n){
      this.target.add(pos,n);
      this.condition(this.target,this);
    }
}

class SparceList{
  final sparce = new Map<int,dynamic>();
  num max;
  
  static create([n]) => new SparceList(n);
  
  SparceList([m]){
    this.max = m;
  }
  
  void get(int k){
    return this.sparce[k];
  }
  
  bool hasKey(int k){
    return this.sparce.containsKey(k);
  }
  
  bool hasValue(t){
    return this.sparce.containsValue(t);  
  }
  
  void add(int k,t){
    if(this.isFull) return;
    this.sparce[k] = t;  
  }
  
  void remove(int k){
    this.sparce.remove(k);  
  }
  
  void propagate(Function n(k,t)){
    this.sparce.forEach(n);
  }
  
  num get length => this.sparce.length;
  
  bool get isFull{
    if(this.max == null || this.max < this.length) return false;
    return true;
  }
  
  List toList(){
    var keys = this.sparce.keys.toList();
    Hub.quickSort(keys, 0, keys.length,(m,n){ if(m < n) return false; return true;});
    return keys;
  }
  
  List sorted(){
    var sorted = new List(), 
        sort = this.toList();
        
    sort.forEach((k){ 
      sorted.add(this.sparce[k]); 
    });
    return sorted;
  }
  
  List unsorted(){
    return this.sparce.values.toList();   
  }
  
  toString(){
    return this.sparce.toString();
  }
  
  void clear(){
    this.sparce.clear();
  }
}

class Switch{
  int _state = -1;
  final onOff = new List<Function>();
  final onOn = new List<Function>();


  static create() => new Switch();

  Switch();

  void switchOff(){
    this._state = 0;
    this.onOff.forEach((f){ f(); });
  }

  void switchOn(){
    this._state = 1;
    this.onOn.forEach((f){ f(); });
  }

  bool on(){
    return this._state == 1;
  }

}

class Distributor<T>{
  List<Function> listeners = new List<Function>();
  final done = new List<Function>();
  final once = new List<Function>();
  final _removal = new List<Function>();
  final Switch _switch = Switch.create();
  String id;
  bool _locked = false;
  
  static create(id) => new Distributor(id);

  Distributor(this.id);
  
  void onOnce(Function n){
    if(this.once.contains(n)) return;
    this.once.add(n);     
  }
  
  void on(Function n){
    if(this.listeners.contains(n)) return;
    this.listeners.add(n);
  }

  void whenDone(Function n){
    if(!this.done.contains(n)) this.done.add(n);
  }
  
  dynamic off(Function m){
    if(!!this._switch.on()){
      return this._removal.add((j){
        return this.listeners.remove(m);
      });
    }
    return this.listeners.remove(m);
  }
  
  void free(){
    this.freeListeners();
    this.done.clear();
    this.once.clear();
  }

  void freeListeners(){
    this.listeners.clear();
  }
  
  void emit(T n){
    if(this.locked) return;
    this.fireOncers(n);
    this.fireListeners(n);
  }
  
  void fireListeners(T n){
    if(this.listeners.length <= 0) return;
    
    this._switch.switchOn();
    Hub.eachAsync(this.listeners,(e,i,o,fn){
      e(n);
      fn(false);
    },(o){
      this.fireDone(n);
      this._switch.switchOff();
      this._fireRemoval(n);
    });   
  }
 
  void fireOncers(T n){
    if(this.once.length <= 0) return null;
    Hub.eachAsync(this.once,(e,i,o,fn){
      e(n);
      fn(false);
    },(o){
      this.once.clear();
    });
  }
  
  void fireDone(T n){
    if(this.done.length <= 0) return;
    Hub.eachAsync(this.done,(e,i,o,fn){
      e(n);
      fn(false);
    });
  }
  
  void _fireRemoval([T n]){
    if(this._removal.length <= 0 || this._switch.on()) return;
    Hub.eachAsync(this._removal,(e,i,o,fn){
      e(n);
      fn(false);
    });
  }

  bool get hasListeners{
    return (this.listeners.length > 0);
  }
  
  void lock(){
    this._locked = true;
  }
  
  void unlock(){
    this._locked = false;
  }
  
  List cloneListeners(){
    return new List<Function>.from(this.listeners);
  }

  void clearDone(){
    this.done.clear();
  }

  bool get locked => !!this._locked;

  int get listenersLength => this.listeners.length; 
  int get doneLength => this.done.length; 

}

class Mutator<T> extends Distributor<T>{
    final List history = new List();
    
    Mutator(String id): super(id);
    
    void replaceTransformersListWith(List<Function> a){
      this.listeners = a;
    }

    void updateTransformerListFrom(Mutator m){
      this.replaceTransformersListWith(m.cloneListeners());
    }

    void emit(T n){
      this.fireListeners(n);
    }
    
    void fireListeners(T n){
      var history = new List();
      history.add(n);
      
      var done = (k){
        this.fireDone(history.last);
        this.fireOncers(history.last);
        history.clear();
      };
      
      Hub.eachAsync(this.listeners,(e,i,o,fn){
          var cur = history.last;
          var ret = e(cur);
          if(ret == null){
            (history.isEmpty ? history.add(cur) : 
              (!history.isEmpty && history.last != cur ? history.add(cur) : null));
          }else history.add(ret);
          fn(false);
      },done);
        
      
    }
    
}

class SymbolCache{
	var _cache = {};
	
	SymbolCache();
		
	Symbol create(String id){
		if(this._cache.containsKey(id)) return this._cache[id];
		return (this._cache[id] = Hub.encryptSymbol(id));
	}
	
	void destroy(String id){
		this._cache.remove(id);
	}
	
	void flush() => this._cache.clear();
	
	String toString() => "SymbolCacheObject";
}

class MapDecorator{
	final storage;
	
	static create(){
		return new MapDecorator();
	}
		
	MapDecorator(): storage = new Map();

	MapDecorator.from(Map a): storage = new Map.from(a);
	
		
	dynamic get(String key){
		if(this.has(key)) return this.storage[key];
	}
			
	bool add(String key,dynamic val){
		if(!this.has(key)){ this.storage[key] = val; return true; }
		return false;
	}

	bool update(String key,dynamic val){
		if(this.has(key)){ this.storage[key] = val; return true; }
		return false;
	}

  bool updateKey(String key,String newKey){
    if(!this.has(key)) return false;
    var val = this.get(key);
    this.destroy(key);
    this.add(newKey,val);
  }

	dynamic destroy(String key){
		if(!this.has(key)) return null; 
		return this.storage.remove(key);		
	}
		
	bool has(String key){
		if(!this.storage.containsKey(key)) return false;
		return true;
	}
	
  bool hasValue(String v){
    if(!this.storage.containsValue(v)) return false;
    return true;
  }

	void onAll(Function n) => this.storage.forEach(n);
	
	void flush(){
		this.storage.clear();
	}
	
	String toString(){
		return this.storage.toString();
	}

}

class SingleLibraryManager{
	Symbol tag;
	final ms = currentMirrorSystem();
	LibraryMirror library;
	
	static create(String n,[LibraryMirror lib]){
		if(lib != null) return new SingleLibraryManager.use(n,lib);
		return new SingleLibraryManager(n);
	}
	
	SingleLibraryManager(name){
		this.tag = Hub.encryptSymbol(name); 
		this._initLibrary();
	}
	
	SingleLibraryManager.use(name,LibraryMirror lib){
		this.tag = Hub.encryptSymbol(name);
		this.library = lib;
	}
	
	void _initLibrary(){
		try{
			var lib = this.ms.findLibrary(this.tag);
			if(lib == null) throw "Unable to find Library: ${Hub.decryptSymbol(this.tag)}";
			//this.library = lib.single;
		}catch(e){
		 	throw "Library Not Found ${this.tag}";
		}
	}
	
	bool matchClassWithInterface(String className,String interfaceName){
		var simpleIName = Hub.encryptSymbol(interfaceName);
		var cl = this.getClass(className);
		if(cl == null) return false;
		var  ci = cl.superinterfaces;
		for(var n in ci){
			if(n.simpleName != simpleIName) continue;
			return true;
		}
		return false;
	}
		
	dynamic getClass(String name){
		return this.library.declarations[Hub.encryptSymbol(name)];
	}
	
	dynamic getSetter(String name){
		return this.library.declarations[Hub.encryptSymbol(name)];
	}
		
	dynamic getGetter(String name){
		return this.library.declarations[Hub.encryptSymbol(name)];	
	}
	
	dynamic getFunction(String name){
		return this.library.declarations[Hub.encryptSymbol(name)];
	}
		
	dynamic getVariable(String name){
		return this.library.declarations[Hub.encryptSymbol(name)];
	}
	
	Map getAllMembers(String name){
		return this.library.topLevelMembers;
	}
			
	dynamic createClassInstance(String name,{String constructor: null,List pos:null,Map<Symbol,dynamic> named:null}){
		var cm = this.getClass(name);
		return cm.newInstance((constructor == null ? name : constructor), pos,named);
	}
	
}

class Counter{
  num _count = 0;
  dynamic handler;
  
  static create(n) => new Counter(n);

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

var _smallA = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"];
var _bigA = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];

class Hub{
  
  static void cycle(int times,Function fn){
    fn(times);
    if(times > 0) return Hub.cycle((times - 1), fn); 
    return null;
  }
  
  static String randomStringsets(int len,[String separator]){
    var set = new List();
    var buffer = new StringBuffer();
    var rand = new math.Random();
    var max = _smallA.length;
    
    Hub.cycle(len, (n){
      var ind = rand.nextInt(max - 1);
      var shake = ind + rand.nextInt((max ~/ 2).toInt());
      
      if(ind >= max) ind = ((ind ~/((n + 1) * 2))).toInt();
      if(shake >= max) shake = ((shake ~/((n+1) * 4))).toInt();
            
      buffer.write(shake);
      buffer.write(_smallA.elementAt(ind));
      buffer.write(ind);
      buffer.write(_bigA.elementAt(shake));
      
      set.add(buffer.toString());
      buffer.clear();
    });
    
    return set.join((separator != null ? separator : '-'));
  }
  
  static dynamic randomString(int len,[int max]){
    var set = Hub.randomStringsets(len);
    return set.substring(0,(max != null ? (max >= set.length ? set.length : max) : set.length));
  }
  
  static Counter createCounter(h){
    return new Counter(h);
  }
  static ListInjector createListInjector(max,[f,g]){
    return ListInjector.create(max,f,g);  
  }
  
  static LengthInjector createLengthInjector(max,[f,g]){
    return LengthInjector.create(max,f,g);  
  }
  
  static PositionInjector createPositionalInjector(max,[f,g]){
    return PositionInjector.create(max, f, g);
  }
  static SparceList createSparceList([max]){
    return SparceList.create(max);
  }
  
  static Mutator createMutator(String id){
    return new Mutator(id);
  }
  
  static Distributor createDistributor(String id){
    return new Distributor(id);
  }
  
  static MapDecorator createMapDecorator(){
    return new MapDecorator();
  }
    
  static int findMiddle(List a,int start,int length,bool compare(n,m)){
    
     int last = (start + (length - 1)).toInt();
     int mid =  ((start + (length / 2))).toInt();
          
     if(!!compare(a.elementAt(start),a.elementAt(last)) && !!compare(a.elementAt(start),a.elementAt(mid))){
        if(!!compare(a.elementAt(mid),a.elementAt(last))) return mid;
        return start;
     }
     
     if(!!compare(a.elementAt(mid),a.elementAt(start)) && !!compare(a.elementAt(mid),a.elementAt(last))){
       if(!!compare(a.elementAt(start),a.elementAt(last))) return start;
       return mid;
     }
     
     if(!!compare(a.elementAt(last),a.elementAt(mid)) && !!compare(a.elementAt(last),a.elementAt(start))){
       if(!!compare(a.elementAt(mid),a.elementAt(start))) return mid;
       return last;
     }
  }
  
  static List quickSort(List a,int first,int size,bool compare(n,m)){
     
     int pivot, mid;
     int last = (first + (size - 1)).toInt();
     int lower = first;
     int high = last;
     
     
     if(size > 1){
       mid = Hub.findMiddle(a, first,size, compare);
       pivot = a[mid];
       a[mid] = a[first];
              
       while(lower < high){
         while(!compare(pivot,a[high]) && lower < high) high -= 1;
                 
         if(high != lower){
           a[lower] = a[high];
           lower += 1;
         }
         
         while(compare(pivot,a[lower]) && lower < high) lower += 1;
                  
         if(high != lower){
           a[high] = a[lower];
           high -= 1;
         }
       }
       
       
       a[lower] = pivot;
       
       Hub.quickSort(a, first, (lower - first), compare);
       Hub.quickSort(a, (lower + 1), (last - lower), compare);
       
       return a;
     }
  }
  
	static bool classMirrorInvokeNamedSupportTest(){
		try{
			var simpleclass = reflectClass(Map);
			Map<Symbol,dynamic> named = new Map<Symbol,dynamic>();
			simpleclass.invoke(new Symbol('toString'),[],named);
		}on UnimplementedError{
			return false;
		}on Exception catch(e){
			return true;
		}
		return true;
	}
	
	static dynamic findClass(libraryName,className){
		var lib = Hub.singleLibrary(libraryName);
		return lib.getClass(className);
	}
		
	static SingleLibraryManager singleLibrary(library){
		return SingleLibraryManager.create(library);
	}
	
	static dynamic findLibrary(library){
		var ms = currentMirrorSystem();
		var lib = ms.findLibrary(Hub.encryptSymbol(library));
		if(lib == null) throw "Unable to find Library: $library";
		return lib;
	}

	
	static void eachAsync(List a,Function iterator,[Function complete]){
    if(a.length <= 0){
      if(complete != null) complete(a);
      return null;    
    }
    
    var total = a.length,i = 0;
    
    a.forEach((f){
      iterator(f,i,a,(err){
          if(err){
            if(complete != null) complete(a);
            return null;
          }
          total -= 1;
          if(total <= 0){
            if(complete != null) complete(a);
            return null;
          }
      });  
      i += 1;
    });
    
  }

	 static void eachAsyncMap(Map a,Function iterator,[Function complete]){
	    if(a.length <= 0){
	      if(complete != null) complete(a);
	      return null;    
	    }
	    
	    var total = a.length;
	    
	    a.forEach((f,v){
	      iterator(v,f,a,(err){
          if(err){
            if(complete != null) complete(a);
            return null;
          }
          total -= 1;
          if(total <= 0){
            if(complete != null) complete(a);
            return null;
          }
      });  
    });
    
  }
	 
  static void eachSyncMap(Map a,Function iterator, [Function complete]){
    if(a.length <= 0){
      if(complete != null) complete(a);
      return null;    
    }
    
    var keys = a.keys.toList();
    var total = a.length,step = 0,tapper;
        
    var fuse = (){
      var key = keys[step];
      iterator(a[key],key,a,(err){
        if(err){
          if(complete != null) complete(a);
          return null;
        }
        step += 1;
        if(step == total){
          if(complete != null) complete(a);
           return null;
        }else return tapper();
      });
    };
     
    tapper = (){ return fuse(); };

    return fuse();
  }
  
	static void eachSync(List a,Function iterator, [Function complete]){
	  if(a.length <= 0){
      if(complete != null) complete(a);
      return null;    
	  }
	  
	  var total = a.length,step = 0,tapper;
	  	  
	  var fuse = (){
	    iterator(a[step],step,a,(err){
	      if(err){
	        if(complete != null) complete(a);
          return null;
	      }
        step += 1;
	      if(step == total){
          if(complete != null) complete(a);
	         return null;
	      }else return tapper();
	    });
	  };
	   
	  tapper = (){ return fuse(); };

	  return fuse();
	}
	
	static Future eachFuture(dynamic a,Function validator){
		var future;
		if(a.isEmpty) return new Future.value(true);
		if(a is List){
			a.forEach((n){
				if(future != null) future.then((_){ return new Future.value(validator(n)); });
				else future = new Future.value(validator(n));
			});
		}
		if(a is Map){
			a.forEach((n,v){
				if(future != null) future.then((_){ return new Future.value(validator(n,v)); });
				else future = new Future.value(validator(n,v));
			});
		}
		return future;
	}
	
	static Future captureEachFuture(dynamic a,Function validator){
		var res = [];
		
		if(a.isEmpty) return new Future.value(true);
		
		if(a is List){
			a.forEach((n){
				res.add(new Future.value(validator(n)));
			});
		}
		if(a is Map){
			a.forEach((n,v){
				res.add(new Future.value(validator(n,v)));
			});
		}
		
		return Future.wait(res);
	}
		
	static final symbolMatch = new RegExp(r'\(|Symbol|\)');
	
	static dynamic throwNoSuchMethodError(Invocation n,Object c){
		throw new NoSuchMethodError(
			c,
			n.memberName,
			n.positionalArguments,
			n.namedArguments);
	}
	
	static SymbolCache createSymbolCache(){
		return new SymbolCache();
	}
		
  static Map encryptNamedArguments(Map params){
    Map<Symbol,dynamic> p = new Map<Symbol,dynamic>();
    if(params.isEmpty) return p;
    params.forEach((k,v){
      if(k is! Symbol) p[Hub.encryptSymbol(k)] = v;
      else p[k] = v;
    });
    return p;
  }

  static Map decryptNamedArguments(Map params){
    Map<String,dynamic> o = new Map<String,dynamic>();
    if(params.isEmpty) return o;
    params.forEach((k,v){
      if(k is String) o[k] = v;
  else o[Hub.decryptSymbol(k)] = v;
    });
    return o;
  }
	
	static Symbol encryptSymbol(String n){
		return new Symbol(n);
	}
	
	static String decryptSymbol(Symbol n){
		return MirrorSystem.getName(n);
	}
	
  static String getClassName(Object m){
		return Hub.decryptSymbol(reflectClass(m).simpleName);
  }
}

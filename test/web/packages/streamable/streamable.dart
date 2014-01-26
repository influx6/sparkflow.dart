 library streamable;

import 'package:ds/ds.dart' as ds;
import 'package:hub/hub.dart';

abstract class Streamer<T>{
  void emit(T e);
  void push();
  void resume();
  void pause();
  void listen(Function n);
  void end();
  void close();
  void pipe(Streamer<T> s);
  void transform(Streamer<T> s);
}

abstract class Broadcast<T>{
  void on(Function n);
  void off(Function n);
  void propagate(T n);
  void add(T n) => this.propagate(n);
}

class Listener<T>{
  final info = Hub.createMapDecorator();

  Listener();

  void emit(T a){}
  void pause(){}
  void resume(){}
  void on(Function n){}
  void off(Function n){}
  void end(){}
}

class Distributor<T>{
  final listeners = new ds.dsList<Function>();
  final done = new ds.dsList<Function>();
  final onced = new ds.dsList<Function>();
  String id;
  dynamic listenerIterator,doneIterator,onceIterator;
  bool _locked = false;
  
  static create(id) => new Distributor(id);

  Distributor(this.id){
    this.listenerIterator = this.listeners.iterator;
    this.doneIterator = this.done.iterator;
    this.onceIterator = this.onced.iterator;
  }
  
  void once(Function n){
    if(this.onceIterator.contains(n)) return;
    this.onced.add(n);     
  }
  
  void on(Function n){
    if(this.listenerIterator.contains(n)) return;
    this.listeners.add(n);
  }

  void whenDone(Function n){
    if(!this.doneIterator.contains(n)) this.done.add(n);
  }
  
  dynamic off(Function m){
    var item = this.listenerIterator.remove(m);
    if(item == null) return null;
    return item.data;
  }
  
  void free(){
    this.listeners.clear();
    this.done.clear();
    this.onced.clear();
  }

  void emit(T n){
    if(this.locked) return;
    this.fireOncers(n);
    this.fireListeners(n);
  }
  
  void fireListeners(T n){
    if(this.listeners.isEmpty) return;
    
    while(this.listenerIterator.moveNext()){
      this.listenerIterator.current(n);
    };
    this.fireDone(n);
  }
 
  void fireOncers(T n){
    if(this.onced.isEmpty) return;
    
    while(this.onceIterator.moveNext()){
      this.onceIterator.current(n);
    };

    this.onced.clear();
  }
  
  void fireDone(T n){
    if(this.done.isEmpty) return;
    while(this.doneIterator.moveNext()){
      this.doneIterator.current(n);
    };
  }

  bool get hasListeners{
    return !(this.listeners.isEmpty);
  }
  
  void lock(){
    this._locked = true;
  }
  
  void unlock(){
    this._locked = false;
  }
  
  bool get locked => !!this._locked;
}


class Streamable<T> extends Streamer<T>{
  
  final ds.dsList<T> streams =  ds.dsList.create();
  final Mutator transformer = Hub.createMutator('streamble-transformer');
  final Distributor initd = Distributor.create('streamable-emitInitiation');
  final Distributor drained = Distributor.create('streamable-drainer');
  final Distributor closed = Distributor.create('streamable-close');
  final Distributor resumer = Distributor.create('streamable-resume');
  final Distributor pauser = Distributor.create('streamable-pause');
  final Distributor listeners = Distributor.create('streamable-listeners');
  dynamic iterator;
  StateManager state,pushState,flush;
  
  static create([n]) => new Streamable(n);

  Streamable([int m]){
    if(m != null) this.streams.setMax(m);
    this.state = StateManager.create(this);
    this.pushState = StateManager.create(this);
    this.flush = StateManager.create(this);
    this.iterator = this.streams.iterator;
  
    this.flush.add('yes', {
      'allowed': (t,c){ return true; }
    });

    this.flush.add('no', {
      'allowed': (t,c){ return false; }
    });
    
    this.pushState.add('strict', {
      'strict': (target,control){ return true; },
      'delayed': (target,control){ return false; },
    });
    
    this.pushState.add('delayed', {
      'strict': (target,control){ return false; },
      'delayed': (target,control){ return true; },
    });

    this.state.add('closed',{
      'closed': (target,control){ return true; },
      'closing': (target,control){ return false; },
      'firing': (target,control){ return false; },
      'paused': (target,control){ return false; },
      'resumed': (target,control){ return false; },
    });
    
    this.state.add('resumed',{
      'closing': (target,control){ return false; },
      'closed': (target,control){ return false; },
      'firing': (target,control){ return false; },
      'paused': (target,control){ return false; },
      'resumed': (target,control){ return true; },
    });
    
    this.state.add('paused',{
      'closing': (target,control){ return false; },
      'closed': (target,control){ return false; },
      'firing': (target,control){ return false; },
      'paused': (target,control){ return true; },
      'resumed': (target,control){ return false; },
    });    

    this.state.add('firing',{
      'closing': (target,control){ return false; },
      'closed': (target,control){ return false; },
      'firing': (target,control){ return true; },
      'paused': (target,control){ return false; },
      'resumed': (target,control){ return true; },
    }); 
  
    this.state.add('closing',{
      'closing': (target,control){ return true; },
      'closed': (target,control){ return false; },
      'firing': (target,control){ return false; },
      'paused': (target,control){ return false; },
      'resumed': (target,control){ return false; },
    }); 
    
    this.transformer.whenDone((n){
      
      this.streams.add(n);
      this.push();
    });
    
    this.state.switchState('resumed');
    this.flush.switchState('no');
    this.pushState.switchState("strict");
    
  }

  Mutator cloneTransformer(){
    var clone = Hub.createMutator('clone-transformer');
    clone.updateTransformerListFrom(this.transformer);
    return clone;
  }
  
  void setMax(int m){
    this.streams.setMax(m);  
  }
  
  void emit(T e){    
    if(e == null) return null;
    
    if(this.streamClosed) return null;  
    
    if(this.isFull){
      if(this.flush.run('allowed')) this.streams.clear();
      else return null;
    }
    
    this.initd.emit(e);
    this.transformer.emit(e);
  }
  
  void emitMass(List a){
    a.forEach((f){
      this.emit(f);
    });  
  }
  
  void on(Function n){
    this.listeners.on(n);
    this.push();
  }
  
  void off(Function n){
    this.listeners.off(n);  
  }
  
  void whenDrained(Function n){
    this.drained.on(n);  
  }
  
  void whenClosed(Function n){
    this.closed.on(n);  
  }
  
  void whenInitd(Function n){
    this.initd.on(n);  
  }
  
  void push(){
    if(this.pushDelayedEnabled) return this.pushDelayed();
    return this.pushStrict();
  }
  
  void pushDelayed(){

    if(!this.hasListeners || this.streams.isEmpty || this.streamFiring || this.streamPaused || this.streamClosed) return null;

    if(this.streams.isEmpty && !this.streamClosing) return null;

    if(!this.streamClosing) this.state.switchState("firing");
    
    while(!this.streams.isEmpty) 
      this.listeners.emit(this.streams.removeHead().data);
    
    if(this.streamClosing && this.streams.isEmpty){
      this.state.switchState('closed');
      this.drained.emit(true);
      this.closed.emit(true);
      this.closed.free();
      this.drained.lock();
      this.closed.lock();
      return null;
    }else this.push();
    
    this.drained.emit(true);
    if(!this.streamClosing) this.state.switchState("resumed");    
  }
  
  void pushStrict(){
        
    if(!this.hasListeners || this.streams.isEmpty || this.streamFiring || this.streamPaused || this.streamClosed) return null;
    
    if(this.streamClosing){
      this.state.switchState('closed');
      this.drained.emit(true);
      this.closed.emit(true);
      this.reset();
      return null;
    }  
    
    this.state.switchState("firing");
    
    while(!this.streams.isEmpty) 
      this.listeners.emit(this.streams.removeHead().data);
    
    this.drained.emit(true);
    this.state.switchState("resumed");
  }
  
  void pause(){
    if(this.streamClosed) return;
    this.state.switchState('paused');
    this.pauser.emit(this);
  }
  
  void resume(){
    if(this.streamClosed) return;
    this.state.switchState('resumed');
    this.resumer.emit(this);
    this.push();
  }
 
  void closeListeners(){
    this.closed.free();
    this.listeners.free();
    this.initd.free();
    this.drained.free();
  }
  
  void reset(){
    if(!this.streamClosed) return;  
    this.closeListeners();
    this.state.switchState("paused");
    this.initd.unlock();
    this.transformer.unlock();
    this.drained.unlock();
    this.listeners.unlock();
    this.closed.unlock();
  }
  
  void lockAllDistributors(){
    this.initd.unlock();
    this.transformer.unlock();
    this.drained.lock();
    this.closed.lock();
    this.listeners.lock();
  }
  
  void end(){
    if(this.streamClosed) return null;
    this.state.switchState('closing');
    this.initd.lock();
  }
  
  void close() => this.end();
  
  void enablePushDelayed(){
    this.pushState.switchState("delayed"); 
  }
  
  void disablePushDelayed(){
    this.pushState.switchState("strict");     
  }
  
  bool get isFull{
    return this.streams.isDense();
  }
  
  void enableFlushing(){
    this.flush.switchState('yes');      
  }
  
  void disableFlushing(){
    this.flush.switchState('no');  
  }
  
  bool get pushDelayedEnabled{
    return this.pushState.run('delayed');  
  }
  
  bool get isEmpty{
    return this.streams.size <= 0;   
  }
  
  bool get streamClosed{
    return this.state.run('closed');  
  }

  bool get streamClosing{
    return this.state.run('closing');  
  }
  
  bool get streamPaused{
    return this.state.run('paused');
  }
  
  bool get streamResumed{
    return this.state.run('resumed');
  }  

  bool get streamFiring{
    return this.state.run('firing');
  }
  
  bool get hasListeners{
    return this.listeners.hasListeners;
  }
  
  Subscriber subscribe(Function fn){
    var sub = Subscriber.create(this);
    sub.on(fn);
    return sub;
  }
}

class Subscriber<T> extends Listener<T>{
  Streamable stream = Streamable.create();
  Streamable source;
  
  static create(c) => new Subscriber(c);

  Subscriber(this.source): super(){
    this.source.on(this.emit);
    this.stream.whenClosed((n){
      this.source.off(this.emit);
      this.source = null;
    });
  }

  Mutator get transformer => this.stream.transformer;

  void setMax(int m){
    this.stream.setMax(m);  
  }

  void enableFlushing(){
    this.stream.enableFlushing(); 
  }
  
  void disableFlushing(){
    this.stream.disableFlushing();
  }
  
  void whenDrained(Function n){
    this.stream.whenDrained(n);
  }
  
  void whenClosed(Function n){
    this.stream.whenClosed(n);
  }
  
  void whenInitd(Function n){
    this.stream.whenInitd(n);
  }

  void off(Function n){
    this.stream.off(n);
  }
  
  void on(Function n){
    this.stream.on(n);
  }

  void emit(T a){
    this.stream.emit(a);
  }

  void emitMass(List a){
    this.stream.emitMass(a);
  }
  
  void pause(){
      this.stream.pause();
  }

  void resume(){
    this.stream.resume();
  }
  
  void end([bool noattr]){
   this.stream.end();
   if(noattr != null && !noattr) this.closeAttributes();
  }
  
  void closeAttributes(){
    //does nothing - removed dynamic properties of invocable for dart2js compatibility
  }
  
  void close([bool n]){
    this.end(n);
  }
}


class MixedStreams{
  
  static Function mixed(List<Streamable> sets){
    return (Injector<T> injectible){
      return (fn,[fns]){
        var mixed = Streamable.create();
        var injector  = injectible;
        
        injector.on((n){
          if(fns != null && fns is Function) return fns(n,mixed,sets,injector);
          mixed.emit(n);
        });
        
        fn(sets,mixed,injector);
        
        return mixed;
      };      
    };
   
  }
  
  static Function combineOrder(List<Streamable> sets){
    return ([checker,fn,fns]){      
      var mixer = MixedStreams.mixed(sets)(Hub.createPositionalInjector(sets.length,checker));
      return mixer((fn != null ? fn : (st,mx,ij){
        Hub.eachAsync(st,(e,i,o,fn){ e.on((j){ ij.push(i,j); }); });
      }),fns);
    };
  }
  
  static Function combineUnOrder(List<Streamable> sets){
    return (checker,[fn,fns]){      
      var mixer = MixedStreams.mixed(sets)(Hub.createListInjector(checker,[],(target){
          var list =  new List.from(target);
          target.clear();
          return list;
      }));
      return mixer((fn != null ? fn : (st,mx,ij){
        Hub.eachAsync(st,(e,i,o,fn){ 
          e.on(ij.push); 
        });
      }),fns);
    };    
  }
  
}
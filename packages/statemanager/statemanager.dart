library StateManager;

import 'package:invocable/invocable.dart';
import 'package:hub/hub.dart';

Function _empty(t,s){}

class State extends ExtendableInvocableBinder{
  Map<String,Function> states;
  dynamic target;
  String name;
  bool _active = false;
 
  static create(t,s,[n]) => new State(t,s,n);
  
  State(this.target,this.states,[String name]){
    this.name = (name == null ? "StateObject" : name);
    //if init and dinit do not exist,provide empty shell,just in case we wish to do some work
    if(this.states['init'] == null) this.states['init'] = _empty;
    if(this.states['dinit'] == null) this.states['dinit'] = _empty;
    
    this.states.forEach((n,k){
      this.addInv(n,val:(){
        if(this.deactivated) return null;
        var m = k(this.target,this);
        return m;
      });
    });
  }
  
  void activate(){
    this.init();
    this._active = true;
  }
  
  void deactivate(){
    this.dinit();
    this._active = false;
  }
  
  bool get activated => !!this._active;
  bool get deactivated => !this._active;
  
}

class StateManager{
    Object target;
    dynamic store,current;
    
    static create(t) => new StateManager(t);
    
    StateManager(this.target){
      this.store = Hub.createMapDecorator();
    }
    
    void add(String name,dynamic m){
      if(m is State) return this._addState(name, m);
      return this._createState(name, m);
    }
    
    void _createState(String name,Map<String,Function> states){
      this.store.add(name,new State(this.target,states,name));
    }
    
    void _addState(String name,State state){
      this.store.add(name,state);  
    }
    
    void removeState(String name){
      this.store.destroy(name);
    }
    
    void switchState(String name){
      if(!this.store.has(name)) return;
      if(this.current != null) this.current.deactivate();
      this.current = this.store.get(name);
      this.current.activate();
      return;
    }
    
    bool get isReady => this.current != null;
    
    dynamic noSuchMethod(Invocation n){
      if(this.current == null) return null;
      return this.current.handleExtendable(n);
    }
}

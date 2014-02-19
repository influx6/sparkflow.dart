part of sparkflow;

/*base class for flow */
abstract class FlowAbstract{
  void boot();
  void shutdown();
  void freeze();
}

abstract class FlowSocket<M>{
  void beginGroup(d);
  void endGroup(d);
  void send(M d);
  void close();
  void attachPort(FlowPort p,b);
  void detachPort(FlowPort p);
  void bindSocket(FlowSocket n,b);
  void unbindSocket(FlowSocket n);
}

/*base class for ports*/
abstract class FlowPort<M>{
  FlowSocket socket;
  
  void connect();
  void send(M data);
  void beginGroup(data);
  void endGroup(data);
  void disconnect();
  void setClass(String m);
  void bindPort(FlowPort p,[n]);
  void unbindPort(FlowPort p);
  void bindSocket(FlowSocket n,[m]);
  void unbindSocket(FlowSocket n);
  void tap(String n,Function m);
  void flushPackets();
  
}

abstract class FlowComponent{
  var _parent;
  final String uuid = hub.Hub.randomString(7);
  final List portClass = ['in','out','err'];
  final alias = new hub.MapDecorator();
  final metas = new hub.MapDecorator.from({'desc':'basic description'});
  final ports = new hub.MapDecorator();
  final bindMeta = new hub.MapDecorator();

  FlowComponent(id){
    this.metas.add('id',id);
    this.metas.add('uuid',this.uuid);
    this.metas.add('group','components/$id');
  }
        
  FlowNetwork get belongsTo => this._parent;
  void set belongsTo(FlowNetwork n){ this._parent = n; }
  
  void setGroup(String g){
  	this.metas.update('group',g);
  }

  bool hasPort(String id){
    return this.ports.has(this.alias.get(id));
  }

  FlowPort port(id){
    return this.ports.get(this.alias.get(id));
  }

  void renamePort(oldName,newName){
    this.alias.updateKey(oldName,newName);
  }
  
  void removePort(name){
    if(!this.alias.has(name)) return;
    var alias = this.alias.get(name);
    var port = this.ports.get(alias);
    if(port == null) return;
    port.close();
    this.alias.destroy(name);
    this.ports.destroy(alias);
  }
        
  void removeAllPorts(){
     this.alias.flush();
     this.ports.onAll((k,v){
        if(v is FlowPort) v.close();
     });
     this.ports.flush();
  }
  
  /*
    {
       uuid: 12213-3223-3232-ase34
       id: centro
       uid; centro-12213-322
       portClass: {'in':[]}
       ports:{
         suck:{
            'in':['out','in'],
            'err': 'out',
         },
         spill:{
            'in':['out','in'],
            'err': 'out',
         },
       }
    }
  */

  Map get toMeta{
    var payload = {};

    payload['metas'] = new Map.from(this.metas.storage);

    payload['metas'].remove('ports');
    payload['metas'].remove('uuid');
    payload['metas'].remove('id');
    payload['metas'].remove('group');
    
    payload['uuid'] = this.metas.get('uuid');
    // payload['desc'] = this.metas.get('desc');
    payload['ports']= {};
    payload['id'] = this.id;
    payload['uid'] = this.UID;
    payload['group'] = this.metas.get('group');
    payload['portClass'] = new List.from(this.portClass);
    payload['portLists'] = this.getPortClassList();
    
    this.alias.onAll((n,k){
        var port = this.port(n);
        payload['ports'][k] = {
          'alias': n,
          'type':  port.portClass,
          'id': k
        };
    });
    
    return payload;
  }

  String get UID => this.metas.get('id')+'#'+this.metas.get('uuid');

  dynamic meta(id,[val]){
    if(val != null && !this.metas.has(id)) this.metas.add(id,val);
    if(val != null && this.metas.has(id)) this.metas.update(id,val);
    return this.metas.get(id); 
  }
  
  void removeMeta(id){
    this.metas.destroy(id);
  }

  Map getPortClassList(){
    var sets = {};
    this.portClass.forEach((n){ sets[n] = new List(); });
    this.alias.onAll((n,k){
      var port = this.port(n);
      sets[port.portClass].add(n);
    });

    return sets;
  }

  String get description => this.metas.get('desc');
  void set description(String desc){ this.metas.update('desc',desc); }
  String get id => this.metas.get('id');
  String get group => this.metas.get('group');
  void set id(String id){ this.metas.update('id',id); }

}

abstract class FlowNetwork{
  final metas = new hub.MapDecorator.from({'desc':'Sparkflow Network Graph'});
  var _parent;

  FlowNetwork(String id){
    this.metas.add('id',id);
  }

  void addComponentInstance(FlowComponent n,String uniq);
  void add(String n,String m);
  void remove(String n);
  void connect(String m,String mport,String n,String nport);
  void disconnect(String m,String n,String j,String k);

  String get id => this.metas.get('id');
  void set id(String id){ this.metas.update('id',id); }
  
  FlowComponent get belongsTo => this._parent;
  void set belongsTo(FlowComponent n){ this._parent = n; }
}

class SocketStream<M>{
  final String uuid = hub.Hub.randomString(3);
  final meta = new hub.MapDecorator();
  final Streamable<M> data = new Streamable<M>();  
  final Streamable end = Streamable.create();  
  final Streamable begin = Streamable.create();
  hub.StateManager state;
  hub.StateManager delimited;
  Streamable stream;
   
  static create() => new SocketStream();
  
  SocketStream(){
    this.state = hub.StateManager.create(this);
    this.delimited = hub.StateManager.create(this);
    
    this.delimited.add('yes', {
      'allowed': (r,c){ return true; }
    });
 
    this.delimited.add('no', {
      'allowed': (r,c){ return false; }
    });
    
    this.state.add('lock', {
      'ready': (r,c){ return false; }
    });    
    
    this.state.add('unlock', {
      'ready': (r,c){ return true;},
    });
    
    this.begin.initd.on((n){
      if(!this.state.run('ready')) this.data.resume();
      this.state.switchState("lock");
      this.data.pause();
    });
    
    this.end.initd.on((n){
      this.data.resume();
      this.state.switchState("unlock");
    });
    
    this.stream = MixedStreams.combineUnOrder([begin,data,end])((tg,cg){
      return this.state.run('ready');
    },null,(cur,mix,streams,ij){   
      if(this.delimited.run('allowed')) return mix.emit(cur.join(this.meta.get('delimiter')));
      return mix.emitMass(cur);
    });
    
    this.setDelimiter('/');
    this.delimited.switchState("no");
    this.state.switchState("unlock");
    this.disableGroupStream();
  }
  
  dynamic get dataTransformer => this.data.transformer;
  dynamic get endGroupTransformer => this.end.transformer;
  dynamic get beginGroupTransformer => this.begin.transformer;
  dynamic get streamTransformer => this.stream.transformer;

  dynamic get dataDrained => this.data.drained;
  dynamic get endGroupDrained => this.end.drained;
  dynamic get beginGroupDrained => this.begin.drained;
  dynamic get streamDrained => this.stream.drained;

  dynamic get dataInitd => this.data.initd;
  dynamic get endGroupInitd => this.end.initd;
  dynamic get beginGroupInitd => this.begin.initd;
  dynamic get streamInitd => this.stream.initd;

  dynamic get dataSegmentBegin => this.data.beginSegment;
  dynamic get endGroupSegmentBegin => this.end.beginSegment;
  dynamic get beginGroupSegmentBegin => this.begin.beginSegment;
  dynamic get streamSegmentBegin => this.stream.beginSegment;

  dynamic get dataSegmentEnd => this.data.endSegment;
  dynamic get endGroupSegmentEnd => this.end.endSegment;
  dynamic get beginGroupSegmentEnd => this.begin.endSegment;
  dynamic get streamSegmentEnd => this.stream.endSegment;

  dynamic get dataClosed => this.data.closed;
  dynamic get endGroupClosed => this.end.closed;
  dynamic get beginGroupClosed => this.begin.closed;
  dynamic get streamClosed => this.stream.closed;

  dynamic get dataPaused => this.data.pauser;
  dynamic get endGroupPaused => this.end.pauser;
  dynamic get beginGroupPaused => this.begin.pauser;
  dynamic get streamPaused => this.stream.pauser;

  dynamic get dataResumed => this.data.resumer;
  dynamic get endGroupResumed => this.end.resumer;
  dynamic get beginGroupResumed => this.begin.resumer;
  dynamic get streamResumed => this.stream.resumer;

  void enableGroupStream(){
     this.stream.setMax(null);
     this.stream.disableFlushing();
  }
  
  void disableGroupStream(){
    this.stream.setMax(0);
    this.stream.enableFlushing();
  }
  
  void setDelimiter(String n){
    this.meta.destroy('delimiter');
    this.meta.add('delimiter', n);
  }
  
  void enableDelimiter(){
    this.delimited.switchState('yes');
  }
  
  void disableDelimiter(){
    this.delimited.switchState("no");
  }
  
  dynamic metas(String key,[dynamic value]){
    if(value == null) return this.meta.get(key);
    this.meta.add(key,value);
  }
  
  void setMax(int n){
    this.data.setMax(n);
    this.stream.setMax(n);
    this.begin.setMax(n);
    this.end.setMax(n);
  }
  
  bool get hasConnections => this.stream.hasListeners;
  
  void close(){
    this.state.close();
    this.delimited.close();
    this.data.close();
    this.begin.close();
    this.stream.close();
    this.end.close();
    this.meta.flush();
  }

  void flushPackets(){
    this.data.forceFlush();
    this.begin.forceFlush();
    this.stream.forceFlush();
    this.end.forceFlush();
  }

}

final socketFilter = (i,n){
  var socks = i.current;
  if(socks.get('socket') == n) return true;
  return false;
};

class Socket<M> extends FlowSocket<M>{
  final Distributor continued = Distributor.create('streamable-streamcontinue');
  final Distributor halted = Distributor.create('streamable-streamhalt');
  final String uuid = hub.Hub.randomString(5);
  final subscribers = ds.dsList.create();
  SocketStream<M> streams;
  FlowPort from,to;
  var filter;
	
  static create([from]) => new Socket(from);
  
  Socket([from]){
    this.streams = new SocketStream<M>();
    this.filter = this.subscribers.iterator;
    if(from != null) this.attachFrom(from);
  }

  void setMax(int m){
    this.streams.setMax(m);  
  }
  
  void flushPackets(){
    this.streams.flushPackets();
  }
  
  bool get hasConnections => this.streams.hasConnections;

  dynamic get dataStream => this.streams.data;
  dynamic get endGroupStream => this.streams.end;
  dynamic get beginGroupStream => this.streams.begin;
  dynamic get mixedStream => this.streams.stream;
  
  dynamic get dataTransformer => this.streams.dataTransformer;
  dynamic get endGroupTransformer => this.streams.endGroupTransformer;
  dynamic get beginGroupTransformer => this.streams.beginGroupTransformer;
  dynamic get mixedTransformer => this.streams.streamTransformer;
  
  dynamic get dataClosed => this.streams.dataClosed;
  dynamic get endGroupClosed => this.streams.endGroupClosed;
  dynamic get beginGroupClosed => this.streams.beginGroupClosed;
  dynamic get mixedClosed => this.streams.streamClosed;

  dynamic get dataDrained => this.streams.dataDrained;
  dynamic get endGroupDrained => this.streams.endGroupDrained;
  dynamic get beginGroupDrained => this.streams.beginGroupDrained;
  dynamic get mixedDrained => this.streams.streamDrained;

  dynamic get dataInitd => this.streams.dataInitd;
  dynamic get endGroupInitd => this.streams.endGroupInitd;
  dynamic get beginGroupInitd => this.streams.beginGroupInitd;
  dynamic get mixedInitd => this.streams.streamInitd;

  dynamic get dataPaused => this.streams.dataPaused;
  dynamic get endGroupPaused => this.streams.endGroupPaused;
  dynamic get beginGroupPaused => this.streams.beginGroupPaused;
  dynamic get mixedPaused => this.streams.streamPaused;

  dynamic get dataResumed => this.streams.dataResumed;
  dynamic get endGroupResumed => this.streams.endGroupResumed;
  dynamic get beginGroupResumed => this.streams.beginGroupResumed;
  dynamic get mixedResumed => this.streams.streamResumed;

  dynamic get dataSegmentBegin => this.streams.dataSegmentBegin;
  dynamic get endGroupSegmentBegin => this.streams.endGroupSegmentBegin;
  dynamic get beginGroupSegmentBegin => this.streams.beginGroupSegmentBegin;
  dynamic get mixedSegementBegin => this.streams.streamSegmentBegin;

  dynamic get dataSegmentEnd => this.streams.dataSegmentEnd;
  dynamic get endGroupSegmentEnd => this.streams.endGroupSegmentEnd;
  dynamic get beginGroupSegmentEnd => this.streams.beginGroupSegmentEnd;
  dynamic get mixedSegementEnd => this.streams.streamSegmentEnd;

  void enableFlushing(){
    this.dataStream.enableFlushing();
    this.beginGroupStream.enableFlushing();
    this.endGroupStream.enableFlushing();
    this.mixedStream.enableFlushing();
  }

  void disableFlushing(){
    this.dataStream.disableFlushing();
    this.beginGroupStream.disableFlushing();
    this.endGroupStream.disableFlushing();
    this.mixedStream.disableFlushing();
  }
    
  void whenHalted(Function m){
    this.halted.on(m);
  }

  void whenHaltedOnce(Function m){
    this.halted.once(m);
  }

  void whenContinued(Function m){
    this.continued.on(m);
  }

  void whenContinuedOnce(Function m){
    this.continued.once(m);
  }

  void metas(String key,[dynamic v]){
    this.streams.metas(key,v);
  }

  void setDelimiter(String n){
    this.streams.setDelimiter(n);
  }
  
  void enableDelimiter(){
    this.streams.enableDelimiter();
  }
  
  void disableDelimiter(){
    this.streams.disableDelimiter();
  }
  
  dynamic on(String which,Function n){

    hub.Funcs.when(hub.Valids.match(which,'data'),(){
        this.dataStream.on(n);
    });
    
    hub.Funcs.when(hub.Valids.match(which,'beginGroup'),(){
        this.beginGroupStream.on(n);
    });
    
    hub.Funcs.when(hub.Valids.match(which,'endGroup'),(){
        this.endGroupStream.on(n);
    });
    
    hub.Funcs.when(hub.Valids.match(which,'mixed'),(){
        this.mixedStream.on(n);
    });
  }

  dynamic off(String which,Function n){
    hub.Funcs.when(hub.Valids.match(which,'data'),(){
        this.dataStream.off(n);
    });
    
    hub.Funcs.when(hub.Valids.match(which,'beginGroup'),(){
        this.beginGroupStream.off(n);
    });
    
    hub.Funcs.when(hub.Valids.match(which,'endGroup'),(){
        this.endGroupStream.off(n);
    });
    
    hub.Funcs.when(hub.Valids.match(which,'mixed'),(){
        this.mixedStream.off(n);
    });
  }

  void detachAll(){
    var sub,handle = this.subscribers.iterator;
    while(handle.moveNext()){
      sub = handle.current;
      sub.get('data').close();
      sub.get('begin').close();
      sub.get('end').close();
      sub.destroy('socket');
      sub.destroy('port');
      sub.flush();
    }
  }

  void attachFrom(from){
    if(this.from != null) return;
    this.from = from;
  }
  
  void detachFrom(){
    if(this.from == null);
    this.from.unbindSocket(this);
  }
  
  void attachTo(FlowPort to){
    if(to != null) return;
    this.to = to;
    this.bindSocket(to.socket);
  }
  
  dynamic attachPort(FlowPort a){
    var sub = this.bindSocket(a.socket);
    if(sub == null) return null;
    sub.add('port',a);
    return sub;
  }

  dynamic detachPort(FlowPort a){
    return this.unbindSocket(a.socket);
  }
  
  dynamic detachTo(){
    if(this.to != null) return null;
    var sub = this.unbindSocket(this.to.socket);
    if(sub == null) return null;
    this.to = null;
    return sub;
  }

  dynamic bindSocket(Socket a){
    if(this.filter.has(a,socketFilter)) return null;
    var sub = hub.Hub.createMapDecorator();
    sub.add('socket',a);
    sub.add('data',this.dataStream.subscribe(a.send));
    sub.add('begin',this.beginGroupStream.subscribe(a.beginGroup));
    sub.add('end',this.endGroupStream.subscribe(a.endGroup));
    this.subscribers.add(sub);
    return sub;
  }
  
  dynamic unbindSocket(Socket a){
    if(!this.filter.has(a,socketFilter)) return null;
    var sub = this.filter.remove(a,null,socketFilter).data;
    sub.get('data').close();
    sub.get('begin').close();
    sub.get('end').close();
    sub.destroy('socket');
    sub.destroy('port');
    return sub;
  }
  
  bool boundedToPort(FlowPort a){
    return this.boundedToSocket(a.socket);
  }

  bool boundedToSocket(FlowSocket a){
    return this.filter.has(a,socketFilter);
  }

  void resume(){
    this.beginGroupStream.resume();
    this.endGroupStream.resume();
    this.dataStream.resume();
    this.mixedStream.resume();
    this.continued.emit(true);
  }
  
  void pause(){
    this.beginGroupStream.pause();
    this.endGroupStream.pause();
    this.dataStream.pause();
    this.mixedStream.pause();
    this.halted.emit(true);
  }

  void beginGroup([group]){
    this.beginGroupStream.emit(group);
  }

  void endGroup([group]){
    this.endGroupStream.emit(group);
  }
  
  void send(data){
    this.dataStream.emit(data);
  }

  void end(){
    this.detachAll();
    //if(this.from) this.from.socket.unbindSocket(this);
    //if(this.to != null) this.unbindSocket(this.to.socket);
    this.from = this.to = null;
    this.streams.close();
  }

  void close() => this.end();

  bool get isResumed => this.streams.stream.streamResumed;
  bool get isPaused => this.streams.stream.streamPaused;

  bool get isConnected => this.isResumed;
  bool get isDisconnected => this.isPaused;
  
  void connect() => this.resume();
  void disconnect() => this.pause();
}

//filters of socket subscribers with aliases
final aliasFilterFn = (it,n){
  if(it.current.info.get('alias') == n) return true;
  return false;
};

/*the channel for IP transmission on a component*/
class Port<M> extends FlowPort<M>{
  final String uuid = hub.Hub.randomString(5);
  hub.Counter counter;
  Map aliases = new Map();
  Socket<M> socket;
  dynamic aliasFilter;
  hub.Mutator _egtransformer,_bgtransformer,_dttransformer;
  String id,componentID,_pc;
  
  static create(id,[cid]) => new Port(id,cid);

  Port(this.id,[cid]):super(){
    this.componentID = cid;
    this.counter = hub.Counter.create(this);
    this.socket = new Socket<M>(this);
    this.aliasFilter = socket.subscribers.iterator;

    this._egtransformer = this.endGroupStream.cloneTransformer();
    this._bgtransformer = this.beginGroupStream.cloneTransformer();
    this._dttransformer = this.dataStream.cloneTransformer();
  }

  void setClass(String pc){
    this._pc = pc;
  }

  String get portClass => this._pc;

  bool get hasConnections => this.socket.hasConnections;

  void enableFlushing(){
    this.socket.enableFlushing();  
  }
  
  void disableFlushing(){
    this.socket.disableFlushing();  
  }

  void setMax(int m){
    this.socket.setMax(m);  
  }
  
  dynamic get dataStream => this.socket.dataStream;
  dynamic get endGroupStream => this.socket.endGroupStream;
  dynamic get beginGroupStream => this.socket.beginGroupStream;
  dynamic get mixedStream => this.socket.mixedStream;
  
  dynamic get dataTransformer => this.socket.dataTransformer;
  dynamic get endGroupTransformer => this.socket.endGroupTransformer;
  dynamic get beginGroupTransformer => this.socket.beginGroupTransformer;
  dynamic get mixedTransformer => this.socket.mixedTransformer;
  
  dynamic get dataDrained => this.socket.dataDrained;
  dynamic get endGroupDrained => this.socket.endGroupDrained;
  dynamic get beginGroupDrained => this.socket.beginGroupDrained;
  dynamic get mixedDrained => this.socket.mixedDrained;

  dynamic get dataClosed => this.socket.dataClosed;
  dynamic get endGroupClosed => this.socket.endGroupClosed;
  dynamic get beginGroupClosed => this.socket.beginGroupClosed;
  dynamic get mixedClosed => this.socket.mixedClosed;

  dynamic get dataInitd => this.socket.dataInitd;
  dynamic get endGroupInitd => this.socket.endGroupInitd;
  dynamic get beginGroupInitd => this.socket.beginGroupInitd;
  dynamic get mixedInitd => this.socket.mixedInitd;

  dynamic get dataPaused => this.socket.dataPaused;
  dynamic get endGroupPaused => this.socket.endGroupPaused;
  dynamic get beginGroupPaused => this.socket.beginGroupPaused;
  dynamic get mixedPaused => this.socket.mixedPaused;

  dynamic get dataResumed => this.socket.dataResumed;
  dynamic get endGroupResumed => this.socket.endGroupResumed;
  dynamic get beginGroupResumed => this.socket.beginGroupResumed;
  dynamic get mixedResumed => this.socket.mixedResumed;

  dynamic get dataSegmentBegin => this.socket.dataSegmentBegin;
  dynamic get endGroupSegmentBegin => this.socket.endGroupSegmentBegin;
  dynamic get beginGroupSegmentBegin => this.socket.beginGroupSegmentBegin;
  dynamic get mixedSegementBegin => this.socket.mixedSegementBegin;

  dynamic get dataSegmentEnd => this.socket.dataSegmentEnd;
  dynamic get endGroupSegmentEnd => this.socket.endGroupSegmentEnd;
  dynamic get beginGroupSegmentEnd => this.socket.beginGroupSegmentEnd;
  dynamic get mixedSegementEnd => this.socket.mixedSegementEnd;

  bool boundedToPort(FlowPort a){
    return this.socket.boundedToPort(a);
  }

  bool boundedToSocket(FlowSocket a){
    return this.socket.boundedToSocket(a);
  }

  void unbindAll() => this.socket.detachAll();

  void _updatePortTransformerClones(){
    //clear the done list
    this._dttransformer.clearDone();
    this._bgtransformer.clearDone();
    this._egtransformer.clearDone();
    //recheck if any change,then update if there is
    if(this.dataTransformer.listenersLength != this._dttransformer.listenersLength){
      this._dttransformer.updateTransformerListFrom(this.dataTransformer);
    }
    if(this.beginGroupTransformer.listenersLength != this._bgtransformer.listenersLength){
      this._bgtransformer.updateTransformerListFrom(this.beginGroupTransformer);
    }
    if(this.endGroupTransformer.listenersLength != this._egtransformer.listenersLength){
      this._egtransformer.updateTransformerListFrom(this.endGroupTransformer);
    }
  }

  dynamic bindTo(FlowPort a){
    return this.socket.attachTo(a);
  }

  dynamic unbindTo(){
    return this.socket.detachTo();
  }

  dynamic bindPort(FlowPort a,[String alias]){
    return this.bindSocket(a.socket,alias);
  }

  dynamic bindSocket(Socket v,[String alias]){
    this.checkAliases();
    var sub = this.socket.bindSocket(v);
    if(sub == null) return null;
    this.counter.tick();
    var id = (alias == null ? this.counter.counter : alias).toString();
    sub.add('alias',id);
    this.aliases[id]= sub;
    return sub;
  }
  
  dynamic unbindPort(FlowPort a){
    return this.unbindSocket(a.socket);
  }

  dynamic unbindSocket(Socket v){
    this.checkAliases();
    var sub = this.socket.unbindSocket(v);
    if(sub == null) return null;
    this.removeSocketAlias(sub.get('alias'));
    sub.flush();
    return sub;
  }
  
  void checkAliases(){
    if(this.aliases.isEmpty) this.counter.detonate();
    return null;
  }
  
  dynamic getAliasOfPort(FlowPort p){
    return this.getAliasOfSocket(p.socket);
  }
  
  dynamic getAliasOfSocket(FlowSocket v){
    var  id;
    hub.Hub.eachSyncMap(this.aliases,(e,i,o,fn){
      if(e.get('socket') == v){
        id = i;
        return fn(true);
      }
      return fn(false);
    });
    
    return id;
  }
  
  dynamic getSocketAlias(String alias){
    var sub = this.aliases[alias];
    if(sub == null)  return null;
    return sub;
  }

  dynamic removeSocketAlias(String alias){
    var sub = this.aliases.remove(alias);
    if(sub == null)  return null;
    return sub;
  }

  void beginGroup(data,[String alias]){
    if(alias != null){
      this._updatePortTransformerClones();
      var sub = this.getSocketAlias(alias);
      if(sub != null){
        var socket = sub.get('socket');
        if(socket == null) return null;        
        this._bgtransformer.whenDone(socket.beginGroup);
        this._bgtransformer.emit(data);
      }      
      return null;
    }
    this.socket.beginGroup(data);
  }

  void send(data,[String alias]){
    if(alias != null){
      this._updatePortTransformerClones();
      var sub = this.getSocketAlias(alias);
      if(sub != null){
        var socket = sub.get('socket');
        if(socket == null) return null;
        this._dttransformer.whenDone(socket.send);
        this._dttransformer.emit(data);
      }
      return null;
    }
    this.socket.send(data);
  }

  void endGroup(data,[String alias]){
    if(alias != null){
      this._updatePortTransformerClones();
      var sub = this.getSocketAlias(alias);
      if(sub != null){
        var socket = sub.get('socket');
        if(socket == null) return null;
        this._egtransformer.whenDone(socket.endGroup);
        this._egtransformer.emit(data);
      }   
      return null;
    }
    this.socket.endGroup(data);
  }
  
  void tap(String w,Function n){
    this.socket.on(w,n);
  }

  void untap(String w,Function n){
    this.socket.off(w,n);
  }

  void resume(){
    if(this.socket == null) return;
    this.socket.resume();
  }

  void pause(){
    if(this.socket == null) return;
    this.socket.pause();
  }

  void connect() => this.resume();
  void disconnect() => this.pause();
  
  bool get isResumed{
    return this.socket.isResumed;
  }

  bool get isPaused{
    this.socket.isPaused; 
  }
  
  bool get isConnected => this.isResumed;
  bool get isDisconnected => this.isPaused;
  
  
  void close(){
    this.socket.close();
    this._dttransformer.clearDone();
    this._bgtransformer.clearDone();
    this._egtransformer.clearDone();
  }

  void enableDelimiter(){
    this.socket.enableDelimiter();
  }
  
  void disableDelimiter(){
    this.socket.disableDelimiter();
  }

  void setDelimiter(String n){
    this.socket.setDelimiter(n);
  }

  void flushPackets(){
    this.socket.flushPackets();
  }

}

final IIPFilter = (it,n){
  if(it.current.uuid == n) return true;
  return false;
};

final IIPDataFilter = (it,n){
  if(it.current['uuid'] != n) return false;
  return true;
};

class PlaceHolder{
  String id,uuid;

  static create(id,uuid) => new PlaceHolder(id,uuid);

  PlaceHolder(this.id,this.uuid);
}

class IIPMeta{
    final Map meta = new Map();

    static create(u,a,s,c) => new IIPMeta(u,a,s,c);

    IIPMeta(uuid,alias,socket,component){
      this.meta['uuid'] = uuid;
      this.meta['socket'] = socket;
      this.meta['alias'] = alias;
      this.meta['component'] = component;
    }

    dynamic get uuid => meta['uuid'];
    dynamic get socket => meta['socket'];
    dynamic get alias => meta['alias'];
    dynamic get component => meta['component'];

    void eraseUUID(){ this.meta['uuid'] = ''; }
    void eraseSocket(){ 
      if(this.meta['socket'] != null) this.meta['socket'].end(); 
      this.meta['socket'] = null; 
    }
    void eraseAlias(){ this.meta['alias'] = ''; }
    void eraseComponent(){ this.meta['component'] = null; }

    void selfDestruct(){
      this.eraseSocket();
      this.eraseComponent();
      this.eraseAlias();
      this.eraseUUID();
      this.meta.clear();
    }

    String toString(){
      return this.meta.toString();
    }
}

class FutureCompiler{
  ds.dsList<Function> futures;
  var futureIterator;

  static create([n]) => new FutureCompiler(n);

  FutureCompiler([int n]){
    this.futures = ds.dsList.create(n);
    this.futureIterator = this.futures.iterator;
  }

  void add(Function n){
    this.futures.add(n);
  }

  void clear(){
    this.futures.clear();
  }

  List generateFutureList(){
    var list = new List();
    this.futureIterator.cascade((it){
      list.add(it.current());
    },(it){
       this.clear();
    });

    if(list.length <= 0) list.add(new Future.value(true));
    return list;
  }

  Future whenComplete(Function n,[Function err]){
    var wait = Future.wait(this.generateFutureList()).then(n);
    if(err != null ) wait.catchError(err);
    return wait;
  }

}

class SparkFlowMessages{

  static Map filterError(String id,String uuid,dynamic error,bool isDF){
    return {
      'type': 'filter',
      'method': (!!isDF ? 'df' : 'bf'),
      'id': id,
      'uuid': uuid,
      'error': error,
      'message':'filter component error'
    };
  }

  static Map IIPSocket(bool isAdd,String id,String uuid){
    return {
      'method': (isAdd ? 'add' : 'remove'),
      'type': 'iipSocket',
      'id':id,
      'uuid': uuid,
      'message':'adding intial information packet socket'
    };
  }

  static Map IIP(bool isAdd,String id){
    return {
      'method': (isAdd ? 'add' : 'remove'),
      'type': 'iip',
      'id':id,
      'message':'adding information packet'
    };
  }

  static Map sendInital(uuid,data){
    return {
      'type':'iip',
      'method': 'sendInitial',
      'uuid': uuid,
      'data': data,
      'message':'sending intial information packets'
    };
  }

  static Map component(String type,String id,String uuid){
    return {
      'id':id,
      'uuid': uuid,
      'type': type,
      'message':'$type component to network'
    };
  }

  static Map network(String type,String from,String to,[String top,String fop,String sid,dynamic error]){
    return {
      'type': type,
      'from': from,
      'to': to,
      'fromPort': fop,
      'toPort': top,
      'socketid':sid,
      'message': '$type operation on network',
      'error': error
    };
  }

  static Map componentConnection(String type,String from,String to,[String top,String fop,String sid,dynamic error]){
    return {
      'type': type,
      'from': from,
      'to': to,
      'fromPort': fop,
      'toPort': top,
      'socketid':sid,
      'message': '$type operation on component',
      'error': error
    };
  }

}
class Network extends FlowNetwork{
  final _networkPorts = new hub.MapDecorator();
  //global futures of freze,boot,shutdown
  Completer _whenAlive = new Completer(),_whenFrozen = new Completer(),_whenDead = new Completer();
  //parent for this network if its a subnet
  var _parent;
  //timestamps
  var startStamp,stopStamp;
  // iterator for the graph and iips
  var graphIterator, iipDataIterator;
  // initial sockets list iterator
  var IIPSocketFilter;
  //graph node placeholder
  var placeholder;
  //network StateManager
  var stateManager;
  //connection map 
  var connections;
  // map of uuid registers with either unique names or uuid
  final uuidRegister = new hub.MapDecorator();
  //uuid of network
  final String uuid = hub.Hub.randomString(5);
  //final outport for the particular network,optionally usable
  // the network error stream
  final errorStream = Streamable.create();
  final iipStream = Streamable.create();
  final componentStream = Streamable.create();
  final networkStream = Streamable.create();
  final connectionStream = Streamable.create();
  //handle connections initiation
  final onReadyConnect = Distributor.create('onAliveConnection-distributor');
  final onReadyDisconnect = Distributor.create('onDeadConnections-distributor');
  // the network state distributors
  final onAlive = Distributor.create('onAlive-distributor');
  final onDead = Distributor.create('onDead-distributor');
  final onFrozen = Distributor.create('onFrozen-distributor');
  // graph of loaded components
  final components = new ds.dsGraph<FlowComponent,int>();
  // list of Initial Information Packets
  final IIPSockets = ds.dsList.create();
  // list of initial packets to sent out on boot
  final IIPackets = ds.dsList.create();
  //connection compiler for connection usage;
  final connectionsCompiler = FutureCompiler.create();
  //disconnection compiler for disconnection usage
  final disconnectionsCompiler = FutureCompiler.create();
  //the graph depthfirst filters
  final ds.GraphFilter dfFilter = new ds.GraphFilter.depthFirst((key,node,arc){
      if(node.data.uuid == key) return node;
      return null;
  });
  //the graph breadthfirst filters
  final ds.GraphFilter bfFilter = new ds.GraphFilter.breadthFirst((key,node,arc){
      if(node.data.uuid == key) return node;
      return null;
  });

  static create(id) => new Network(id);

  Network(id): super(id){
   this.dfFilter.use(this.components);
   this.bfFilter.use(this.components);
   // this.graphIterator = this.components.iterator;
   this.IIPSocketFilter = this.IIPSockets.iterator;
   this.iipDataIterator = this.IIPackets.iterator;
   this.placeholder = this.components.add(PlaceHolder.create('placeholder',hub.Hub.randomString(7)));
   this.uuidRegister.add('placeholder',this.placeholder.data.uuid);
   this.stateManager = hub.StateManager.create(this);
  
   this._networkPorts.add('out',Port.create('networkOutport'));
   this._networkPorts.get('out').setClass('out');
   //inport for the particular network,optionally usable
   this._networkPorts.add('in',Port.create('networkInport'));
   this._networkPorts.get('in').setClass('in');
   // the error stream
   this._networkPorts.add('err',Port.create('networkError'));
   this._networkPorts.get('err').setClass('err');
   
   this.connections = ConnectionMeta.create(this);

   this.stateManager.add('dead',{
      'frozen': (t,c){ return false; },
      'dead': (t,c){ return true; },
      'alive': (t,c){ return false; },
   });
   
   this.stateManager.add('frozen',{
      'frozen': (t,c){ return true; },
      'dead': (t,c){ return false; },
      'alive': (t,c){ return false; }
   });

   this.stateManager.add('alive',{
      'frozen': (t,c){ return false; },
      'dead': (t,c){ return false; },
      'alive': (t,c){ return true; }
   });

   this.stateManager.switchState('dead');
   this.metas.add('uuid',this.uuid);
   this.metas.add('id',this.id);

   this.connectionStream.on((e){

     if(e['to'] == '*'){

         if(e['type'] == 'loop' || e['type'] == 'link'){
           this.connections.addConnection(e['toPort'],e['from'],e['fromPort'],e['socketid']);
         }

         if(e['type'] == 'unloop' || e['type'] == 'unlink'){
           this.connections.removeConnection(e['toPort'],e['from'],e['fromPort'],e['socketid']);
         }
     }

     if(e['from'] == '*'){

         if(e['type'] == 'loop' || e['type'] == 'link'){
           this.connections.addConnection(e['fromPort'],e['to'],e['toPort'],e['socketid']);
         }

         if(e['type'] == 'unloop' || e['type'] == 'unlink'){
           this.connections.removeConnection(e['fromPort'],e['to'],e['toPort'],e['socketid']);
         }
     }
     
   });

  }
  
  FlowPort port(String n) => this._networkPorts.get(n);
  
  FlowPort makePort(String n,String type){
    if(this._networkPorts.has(n)) return null;
    var port = Port.create(n, this.id);
    port.setClass(type);
    this._networkPorts.add(n, port);
    return port;
  }
  
  FlowPort removePort(String n){
    if(n == ('in' || 'err' || 'out')) return null;
    this._networkPorts.destroy(n);
  }
  
  FlowPort get nout => this._networkPorts.get('out');
  FlowPort get nin => this._networkPorts.get('in');
  FlowPort get nerr => this._networkPorts.get('err');
  
  void close(){
    this.shutdown();
    this.graph.cascade((e){
      var current = e.current.data;
      if(current is FlowComponent) current.close();
    },(e){
      this.graph.nodes.free();
      closeNetworkStreams();
    });    
  }

  void lockNetworkStreams(){
    this._networkPorts.onAll((i,e){ e.pause(); });
    this.errorStream.pause();
    this.connectionStream.pause();
    this.componentStream.pause();
    this.networkStream.pause();
    this.iipStream.pause();
  }

  void unlockNetworkStreams(){
    this._networkPorts.onAll((i,e){ e.resume(); });
    this.errorStream.resume();
    this.connectionStream.resume();
    this.componentStream.resume();
    this.networkStream.resume();
    this.iipStream.resume();
  }

  void closeNetworkStreams(){
    this._networkPorts.onAll((i,e){ e.close(); });
    this.errorStream.close();
    this.connectionStream.close();
    this.componentStream.close();
    this.networkStream.close();
    this.iipStream.close();
  }

  Future get whenAlive => this._whenAlive.future;
  Future get whenDead => this._whenDead.future;
  Future get whenFrozen => this._whenFrozen.future;

  Future filter(String m,[bool bf]){
    var bff = (bf == null ? false : bf);
    if(!!bff) return this.filterBF(m);
    return this.filterDF(m);
  }

  Future filterDF(String m){
    var id = this.uuidRegister.get(m);
    if(id == null) return new Future.error(new Exception('Not Found!'));
    return this.dfFilter.filter(id).then((_){
      return _;
    }).catchError((e){ 
      this.networkStream.emit(SparkFlowMessages.filterError(m,id,e,true));
    });
  }

  Future filterBF(String m){
    var id = this.uuidRegister.get(m);
    if(id == null) return new Future.error(new Exception('Not Found!'));
    return this.bfFilter.filter(id).then((_){
      return _;
    }).catchError((e){ 
      this.networkStream.emit(SparkFlowMessages.filterError(m,id,e,false));
    });
  }

  dynamic filterIIPSocket(alias,[Function n]){
    var id = this.uuidRegister.get(alias);
    if(id == null) return null;
    var iip = this.IIPSocketFilter.get(id,IIPFilter);
    if(iip == null) return null;
    return iip.data;  
  }

  dynamic addIIPSocket(Component component,String id,[Function n]){
    if(!this.uuidRegister.has(id)) return null;

    if(this.filterIIPSocket(id) != null) return null;

    var iip = IIPMeta.create(component.uuid,id,Socket.create(),component);
    if(n != null) n(iip);

    this.IIPSockets.add(iip);
    this.iipStream.emit(SparkFlowMessages.IIPSocket(true,id,component.uuid));
    return iip;
  }

  dynamic removeIIPSocket(alias,[Function fn]){
    if(!this.uuidRegister.has(alias)) return null;
    var id = this.uuidRegister.get(alias);
    if(id == null) return null;
    var sock =  this.IIPSocketFilter.remove(id,IIPFilter);
    if(fn != null) fn(sock);
    sock.selfDestruct();
    this.iipStream.emit(SparkFlowMessages.IIPSocket(false,id,sock.component.uuid));
    return sock;
  }

  dynamic addInitial(alias,data){
    if(!this.uuidRegister.has(alias)) return null;

    if(this.isDead || this.isFrozen){
        this.iipStream.send(SparkFlowMessages.IIP(true,alias));
        return this.IIPackets.add({ 'uuid': alias, 'data': data});
    };

    var socket = this.filterIIPSocket(alias);
    if(socket != null) socket.socket.send(data);

    this.iipStream.emit(SparkFlowMessages.IIP(true,alias));
    return socket;
  }

  dynamic removeInitial(alias,[Function n]){
    if(!this.uuidRegister.has(alias) || this.isAlive) return null;

    var data,uuid = this.uuidRegister.get(alias);
    data = this.iipDataIterator.remove(uuid,IIPDataFilter);
    if(n != null) n(data);
    this.iipStream.emit(SparkFlowMessages.IIP(false,alias));
    return data;
  }

  void sendInitials(){
    if(this.isAlive || this.IIPackets.isEmpty) return null;
    this.iipDataIterator.cascade((it){
      var f = it.current;
      var socket = this.filterIIPSocket(f['uuid']);
      if(socket != null) socket.socket.send(f['data']);
    },(it){
      this.IIPackets.clear();
    });
 
    this.iipStream.send({ 'type':"sendInitial", 'message': 'sending out all initials' });
  }

  Future _addComponent(FlowComponent a,String id,[Function n]){
    var node = this.components.add(a);
    this.components.bind(this.placeholder,node,0);
    this.components.bind(node,this.placeholder,1);
    this.uuidRegister.add(id,a.uuid);
    this.addIIPSocket(a,id,(meta){
      meta.socket.attachPort(meta.component.port('option'));
      if(n != null) n(meta.component);
    });
    this.componentStream.emit(SparkFlowMessages.component('addComponent',id,a.uuid));
    return new Future.value(node);
  }

  Future addComponentInstance(FlowComponent a,String id,[Function n]){
    return this._addComponent(a,id,n);
  }

  Future add(String path,String id,[Function n,List a,Map m]){
    if(!SparkRegistry.hasGroupString(path)) return new Future.error(new Exception('Component not found!'));
    return this._addComponent(SparkRegistry.generateFromString(path,a,m),id,n);
  }


  Future remove(String a,[Function n,bool bf]){
    if(!this.uuidRegister.has(a)) return null;

    var comso = this.filter(a,bf);
    return comso.then((_){
      if(n != null) n(_.data);
      _.data.detach();
      this.components.eject(_);
      this.removeIIPSocket(a);
      this.componentStream.emit(SparkFlowMessages.component('removeComponent',a,_.data.uuid));
    }).catchError((e){
      this.componentStream.emit({'type':'network-remove', 'error': e, 'component': a });
    });
  }

  Network connect(String a,String aport,String b, String bport,[String sockid,bool bf]){
    if(!this.uuidRegister.has(a)) return null;
    if(!this.uuidRegister.has(b)) return null;

    var waiter = (){
      var comso = this.filter(a,bf);
      var comsa = this.filter(b,bf);
      return Future.wait([comso,comsa]).then((_){
          var from = _[0], to = _[1];
          from.data.bind(aport,to.data,bport,sockid);
          this.components.bind(from,to,{'from': a,'to':b,'fromPort':aport,'toport':b,'socketId': sockid});
          this.connectionStream.emit(SparkFlowMessages.network('connect',a,b,bport,aport,sockid));
          return _;
        }).catchError((e){
          this.connectionStream.emit(SparkFlowMessages.network('connect',a,b,bport,aport,sockid,e));
      });
    }; 

    this.connectionsCompiler.add(waiter);
    return this;
  }

  Network disconnect(String a,String aport,String b,[String bport,String sockid,bool bf]){
    if(!this.uuidRegister.has(a)) return null;
    if(!this.uuidRegister.has(b)) return null;

    var wait = (){
      var comso = this.filter(a,bf);
      var comsa = this.filter(b,bf);
      return  Future.wait([comso,comsa]).then((_){
        var from = _[0], to = _[1];
        from.data.unbind(aport,to.data,bport,sockid);
        this.components.unbind(from,to);
        this.connectionStream.emit(SparkFlowMessages.network('disconnect',a,b,bport,aport,sockid));
        return _;
      }).catchError((e){
        this.connectionStream.emit(SparkFlowMessages.network('disconnect',a,b,bport,aport,sockid,e));
      });
    };

    this.disconnectionsCompiler.add(wait);
    return this;
  }

  Network loopPorts(String p,String s,[String sid]){
    var wait = (){
      var p1 = this.port(p);
      var p2 = this.port(s);

      if(hub.Valids.exist(p1) && hub.Valids.exist(p2)){
        p1.bindPort(p2,sid);
        this.connectionStream.emit(SparkFlowMessages.network('loopPorts','*','*',p,s,sid));
      }  
      return new Future.value([p1,p2]);
    };
    
    this.connectionsCompiler.add(wait);
    return this;
  }

  Network unloopPorts(String p,String s,[String sid]){
    var wait = (){
      var p1 = this.port(p);
      var p2 = this.port(s);

      if(hub.Valids.exist(p1) && hub.Valids.exist(p2)){
        p1.unbindPort(p2);
        this.connectionStream.emit(SparkFlowMessages.network('unloopPorts','*','*',p,s,sid));
      }
      return new Future.value([p1,p2]);
    };

    this.disconnectionsCompiler.add(wait);
    return this;
  }

  Future freeze(){
    if(this.isFrozen) return this.whenFrozen;

    var completer = this._whenFrozen = (!this._whenFrozen.isCompleted ? this._whenFrozen : new Completer());
    this.connectionsCompiler.whenComplete((_){

      if(this.isFrozen || this.isDead){
         completer.complete(this);
         return completer.future;
      }

      this._whenAlive = (this._whenAlive.isCompleted ? new Completer() : this._whenAlive);
      this._whenDead = (this._whenDead.isCompleted ? new Completer() : this._whenDead);

      this.components.cascade((it){
          if(it.current.data == this.placeholder.data) return;
          it.current.data.freeze();
      },(it){
        completer.complete(this);
      });


      this.stateManager.switchState('frozen');
      this.networkStream.emit({ 'type':"freezeNetwork", 'message': 'freezing/pausing network operations','status':true});
      this.onFrozen.emit(this);
      this.lockNetworkStreams();
      return completer.future;
    },(e){ throw e; });

    return this.whenFrozen;
  }

  Future shutdown(){
    if(this.isDead) return this.whenDead;

    this.onReadyDisconnect.emit(this);
    var completer = this._whenDead = (!this._whenDead.isCompleted ? this._whenDead : new Completer());
    this.disconnectionsCompiler.whenComplete((_){

        if(this.isDead){
           completer.complete(this);
           return completer.future;
        }

        this._whenAlive = (this._whenAlive.isCompleted ? new Completer() : this._whenAlive);
        this._whenFrozen = (this._whenFrozen.isCompleted ? new Completer() : this._whenFrozen);

        this.components.cascade((it){
            if(it.current.data == this.placeholder.data) return;
            it.current.data.shutdown();
        },(it){
          completer.complete(this);
        });
        this.stateManager.switchState('dead');
        this.networkStream.emit({ 'type':"shutdownNetwork",'status':true, 'message': 'shutting down/killing network operations'});
        this.onDead.emit(this);
        this.stopStamp = new DateTime.now();
        this.connections.flush();

        return completer.future;
    },(e){ throw e; });

    return this.whenDead;
  }

  Future boot(){
    if(this.isAlive) return this.whenAlive;

    var wasfrozen = this.isFrozen;
    if(!wasfrozen) this.onReadyConnect.emit(this);

    var completer  = this._whenAlive = (!this._whenAlive.isCompleted ? this._whenAlive : new Completer());
    this.connectionsCompiler.whenComplete((_){

      if(this.isAlive){
         completer.complete(this);
         return completer.future;
      }

      if(this.isFrozen || this.isDead){

        this._whenDead = (this._whenDead.isCompleted ? new Completer() : this._whenDead);
        this._whenFrozen = (this._whenFrozen.isCompleted ? new Completer() : this._whenFrozen);

        this.components.cascade((it){
          if(it.current.data == this.placeholder.data) return;
          it.current.data.boot();
        },(it){
          completer.complete(this);
        });
      }

      this.sendInitials();
      this.stateManager.switchState('alive');
      this.networkStream.emit({ 'type':"bootingNetwork", 'status':true,'message': 'booting network operations'});
      this.onAlive.emit(this);
      this.unlockNetworkStreams();
      this.startStamp = new DateTime.now();

      return completer.future;
    },(e){ throw e; });

    return this.whenAlive;
  }

  Map get toMeta{
    var meta = {};
    meta['metas'] = new Map.from(this.metas.storage);
    meta['ports'] = {};
    meta['id'] = this.id;

    this._networkPorts.onAll((e,k){
      meta['ports'][e] = {
        'type': k.portClass,
        'id': e,
      };
    });

    return meta;
  }

  Map generateMap(Function n,Function m){
    var meta = {};
    n(meta);

    this.graph.cascade((e){
      var current = e.current.data;
      if(current is FlowComponent){
        m(meta,current);
      }
    });

    return meta;
  }

  Map get componentsMeta{
    return this.generateMap((meta){
      meta['*'] = this.toMeta;
    },(meta,comp){
        var m = meta[comp.id] = comp.toMeta;
        m.remove('portClass');
        m.remove('portLists');
        // m.remove('uuid');
    });
  }

  Map get connectionsMeta{
    return this.generateMap((meta){
      meta['*'] = this.toMeta;
      meta["*"]['connections'] =  new Map.from(this.connections.storage);
      meta['*'].remove('metas');
      meta['*'].remove('ports');
    },(meta,comp){
        var m = meta[comp.id] = comp.toMeta;
        m['connections'] = comp.connectionsMap;
        m.remove('portClass');
        m.remove('portLists');
        m.remove('ports');
        m.remove('metas');
    });
  }

  dynamic get graph{
  	return this.components;
  }

  bool get isAlive{
    return this.stateManager.run('alive');
  }

  bool get isFrozen{
    return this.stateManager.run('frozen');
  }

  bool get isDead{
    return this.stateManager.run('dead');
  }

  dynamic UUID(String id){
    return this.uuidRegister.get(id);
  }

  dynamic hasUUID(String id){
    return this.uuidRegister.has(id);
  }

  String get UID => this.metas.get('id')+'#'+this.metas.get('uuid');
  
  bool get isEmpty => this.components.isEmpty;

  void onAliveConnect(Function n){
    this.onReadyConnect.on(n);
  }

  void onDeadDisconnect(Function n){
    this.onReadyDisconnect.on(n);
  }

  void onAliveNetwork(Function n){
    this.onAlive.on(n);
  }

  void onFrozenNetwork(Function n){
    this.onFrozen.on(n);
  }

  void onDeadNetwork(Function n){
    this.onDead.on(n);
  }

  void ensureBinding(String from,String fp,String to,String tp,[String sid,bool f]){
    this.onAliveConnect((net){
       return this.doBinding(from,fp,to,tp,sid,f);
    });
  }

  void ensureUnbinding(String from,String fp,String to,String tp,[String sid,bool f]){
    this.onDeadDisconnect((net){
       return this.doUnBinding(from,fp,to,tp,sid,f);
    });
  }

  void looseBinding(String from,String fp,String to,String tp,[String sid,bool f]){
     return this.doBinding(from,fp,to,tp,sid,f);
  }

  void looseUnbinding(String from,String fp,String to,String tp,[String sid,bool f]){
     return this.doUnBinding(from,fp,to,tp,sid,f);
  }

  Network link(String nport,String com,String inport,[String sid,bool bf,bool inverse]){
    if(!this._networkPorts.has(nport)) return null;
    inverse = hub.Hub.switchUnless(inverse,false);
    this.connectionsCompiler.add((){
      return this.filter(com,bf).then((_){
        if(!!inverse){
         this.connectionStream.emit(SparkFlowMessages.network('link','*',com,inport,nport,sid));        
          _.data.port(inport).bindPort(this.port(nport),sid); 
          return _;
        }
        
        this.port(nport).bindPort(_.data.port(inport),sid);    
        this.connectionStream.emit(SparkFlowMessages.network('link',com,'*',nport,inport,sid));
        return _;
      });
    });

    return this;
  }

  Network unlink(String nport, String com,String comport,[String sid,bool bf,bool inverse]){
    if(!this._networkPorts.has(nport)) return null;
    inverse = hub.Hub.switchUnless(inverse,false);
    this.disconnectionsCompiler.add((){
        return this.filter(com,bf).then((_){
        if(!!inverse){
          this.connectionStream.emit(SparkFlowMessages.network('unlink','*',com,comport,nport,sid));        
          _.data.port(comport).unbindPort(this.port(nport));
          return _;  
         }

        this.port(nport).unbindPort(_.data.port(comport)); 
        this.connectionStream.emit(SparkFlowMessages.network('unlink',com,'*',nport,comport,sid));
        return _;
      });
    });
   return this;
  }
  
  void doBinding(String from,String fp,String to,String tp,[String sid,bool f]){
      
      hub.Funcs.when((from == to && to != "*"),(){

          this.filter(from).then((n){
            n.data.loopPorts(tp,fp);
            this.connectionStream.emit(SparkFlowMessages.network('loop',from,to,fp,tp,sid));
          }).catchError((e){
            this.connectionStream.emit(SparkFlowMessages.network('loop',from,to,fp,tp,sid,e));
          });

      });

      hub.Funcs.when((from == "*" && to == "*"),(){
          return this.loopPorts(fp,tp);
      });

      hub.Funcs.when((from != "*" && to != "*"),(){
          return this.connect(from,fp,to,tp,sid,f);
      });

      hub.Funcs.when((from == "*" && to != '*'),(){
        return this.link(fp,to,tp,sid,f,true);
      });

      hub.Funcs.when((from != "*" && to == '*'),(){
        return this.link(tp,from,fp,sid,f); 
      });

  }

  void doUnBinding(String from,String fp,String to,String tp,[String sid,bool f]){

      hub.Funcs.when((from == to && to != "*"),(){

          this.filter(from).then((n){
            n.data.unloopPorts(tp,fp);
            this.connectionStream.emit(SparkFlowMessages.network('unloop',from,to,fp,tp,sid));
          }).catchError((e){
            this.connectionStream.emit(SparkFlowMessages.network('unloop',from,to,fp,tp,sid,e));
          });
          
      });

      hub.Funcs.when((from == "*" && to == "*"),(){
          return this.unloopPorts(fp,tp);
      });

      hub.Funcs.when((from != "*" && to != "*"),(){
        return this.disconnect(from,fp,to,tp,sid,f);
      });

      hub.Funcs.when((from == "*" && to != '*'),(){
        return this.unlink(fp,to,tp,sid,f,true);
      });

      hub.Funcs.when((from != "*" && to == '*'),(){
        return this.unlink(tp,from,fp,sid,f);
      });

  }


}

class ConnectionMeta extends hub.MapDecorator{
    dynamic handler;

    static create(n) => new ConnectionMeta(n);
    ConnectionMeta(this.handler): super();

    dynamic filterUUIDPort(List a,String port,[String sockid]){
      return hub.Enums.filterKeys(a,(e,i,o){
        if(e['port'] == port){
          if((sockid != null && e['socketId']) != null && sockid != e['socketId']) return false;
          return true;
        }
        return false;
      });

    }

    dynamic filterPortLevel(hub.MapDecorator ports,String uuid,String port,[String sockid]){
      if(!ports.has(uuid)) return null;
      return this.filterUUIDPort(ports.get(uuid),port,sockid);
    }

    void addConnection(String ports,String uuid,String port,[String sockid]){
      if(!this.has(ports)) this.add(ports,new hub.MapDecorator());
      var cport = this.get(ports);
      if(!cport.has(uuid)) cport.add(uuid,[]);
      var uuidp = cport.get(uuid);
      var has = this.filterUUIDPort(uuidp,port,sockid);
      hub.Funcs.when(has.length == 0,(){
        uuidp.add({ 'port':port, 'socketId':sockid});
      });
    } 

    void removeConnection(String ports,String uuid,String port,[String sockid]){
    	if(!this.has(ports)) return;
      
      var core = this.get(ports);
      if(!core.has(uuid)) return;

      var item = this.filterPortLevel(core,uuid,port,sockid);
      var uuidp = core.get(uuid);
      hub.Funcs.when(hub.Valids.exist(uuidp),(){
        item.forEach((n){ uuidp.removeAt(n); });
        if(uuidp.length == 0) core.destroy(uuid);
      });
      
    }
}

/*class for component*/
class Component extends FlowComponent{
  final connectionStream = Streamable.create();
  final stateStream = Streamable.create();
  var connections,network,_optionsPort,_networkIIP;

  static registerComponents(){
    SparkRegistry.register("components", 'component', Component.create);
  }
  
  static create([String id]) => new Component(id);
  static createFrom(Map m) => new Component.From(m);

  factory Component.From(Map meta){
    var payload = new hub.MapDecorator.from(meta);

    if(!payload.has('ports')) throw "lacks port information";
    if(!payload.has('id')) throw "lacks id information";

    var proto = Component.create(payload.get('id'));
    
    proto.metas.storage.addAll(payload.get('metas'));
    
    proto.setGroup(payload.get('metas')['group']);

    if(proto.portClass.length != payload.get('portClass').length){
        proto.portClass.clear();
        proto.portClass.addAll(payload.get('portClass'));
    }

    var defaultPorts = new Map.from(proto.ports.storage);
    proto.alias.flush();
    proto.ports.flush();
    payload.get('ports').forEach((n,k){
      var port = defaultPorts[n] == null ? new Port(n,proto.id) : defaultPorts[n];
      port.setClass(k['type']);
      proto.makePort(n,k['type'],port);
      proto.renamePort(n,k['alias']);
    });
    
    return proto;
  }

  Component([String id]): super((id == null ? 'Component' : id)){
    this.connections = ConnectionMeta.create(this);
    this._optionsPort = Port.create('option',this.id);
    this._networkIIP = Port.create('subnet-iip',this.id);

    this.makePort('in','in');
    this.makePort('out','out');
    this.makePort('err','err');

    this.alias.add('in','in');
    this.alias.add('out','out');
    this.alias.add('err','err');

    this.connectionStream.on((e){
      
      hub.Funcs.when(hub.Valids.match(e['type'],'bind'),(){
        this.connections.addConnection(e['fromPort'],e['to'],e['toPort'],e['socketid']);
      });

      hub.Funcs.when(hub.Valids.match(e['type'],'unbind'),(){
        this.connections.removeConnection(e['fromPort'],e['to'],e['toPort'],e['socketid']);
      });

    });

  }

  void subnetPortConnect(){
    var n = this.network;
    this.port('iip').tap('data',(v){
        if(v is Map) n.addInitial(v['id'],v['data']);
    });
    //this.port('in').bindPort(n.nin);
    //n.nout.bindPort(this.port('out'));
  }

  void subnetPortDisconnect(){
    var n = this.network;
    this.port('iip').flushPackets();
    // this.port('in').unbindPort(n.nin);
    //n.nout.unbindPort(this.port('out'));
  }

  FlowPort port(String n){
    if(n == 'option') return this.optionsPort;
    if(n == 'iip') return this.subnetIIPPort;
    return super.port(n);
  }
  
  FlowPort get optionsPort => this._optionsPort;
  FlowPort get subnetIIPPort => this._networkIIP;
    
  void useSubnet(Network n){
    if(this.network != null) return null;
    this.network = n;
    this.subnetPortConnect();
  }

  void enableSubnet(){
    this.network = Network.create(this.id+':Subnet');
    this.subnetPortConnect();
  }

  void disableSubnet(){
    if(this.network == null) return;
    this.subnetPortDisconnect();
    this.network.close();
    this.network = null;
  }

  Map get connectionsMap{
    return new Map.from(this.connections.storage);
  }

  Future boot(){
    this.ports.onAll((k,n){
       n.resume();
    });
    this.stateStream.emit({'type':'boot','id': this.id,'uuid':this.metas.get('uuid')});
    if(this.network != null) return this.network.boot();
    return new Future.value(this);
  }

  Future freeze(){
    this.ports.onAll((k,n){
       n.pause();
    });   
    this.stateStream.emit({'type':'freeze','id': this.id,'uuid':this.metas.get('uuid')});
    if(this.network != null) return this.network.freeze();
    return new Future.value(this);
  }

  Future shutdown(){
    this.ports.onAll((k,n){
       n.close();
    });
    this.stateStream.emit({'type':'shutdown','id': this.id,'uuid':this.metas.get('uuid')});
    if(this.network != null) return this.network.shutdown();
    return new Future.value(this);
  }

  dynamic bind(String myport,Component component,String toport,[String mysocketId]){
    if(!this.hasPort(myport) || !component.hasPort(toport)) return null;

    var myPort = this.port(myport),
          toPort = component.port(toport);

    this.connectionStream.emit(SparkFlowMessages.componentConnection('bind',component.UID,this.UID,toport,myport,mysocketId));
    return toPort.bindPort(myPort,mysocketId);
  }

  dynamic unbind(String myport,Component component,String toport,[String mysocketId]){
    if(!this.hasPort(myport) || !component.hasPort(toport)) return null;

    var myPort = this.port(myport),
          toPort = component.port(toport);
    
    
    this.connectionStream.emit(SparkFlowMessages.componentConnection('unbind',component.UID,this.UID,toport,myport,mysocketId));
    return toPort.unbindPort(myPort);
  }

  FlowPort makePort(String id,String type,[Port p,bool override]){
    if(!this.portClass.contains(type)) throw "Please provide a valid port class: in,out,err,option";

    if(this.alias.has(id) && (!override || override == null)) return null;
    
    var aid = this.alias.get(id);
    var port = (p == null ? Port.create(id,this.id) : p);
    port.setClass(type);
    if(override != null && !!override){
      this.ports.get(aid).close();
      this.ports.update(aid,port);
    } 
    else{
      this.alias.add(id,id);
      this.ports.add(this.alias.get(id),port);
    }

    (this.metas.has('ports') ? this.metas.update('ports',this.getPortClassList()) : 
      this.metas.add('ports',this.getPortClassList()));
    return this.ports.get(this.alias.get(id));
  }
  

  void close(){
    this.disableSubnet();
    this.ports.onAll((n) => n.detach());
  }
  
  void unloopPorts(String v,String u){
    var from = this.port(v);
    var to = this.port(u);

    if(to != null && from != null){
      from.unbindPort(to);
 	  this.connectionStream.emit(SparkFlowMessages.componentConnection('loop',this.UID,this.UID,u,v,null));
    }
  }

  void loopPorts(String v,String u){
    var from = this.port(v);
    var to = this.port(u);

    if(to != null && from != null){
      from.bindPort(to);
 	  this.connectionStream.emit(SparkFlowMessages.componentConnection('loop',this.UID,this.UID,u,v,null));
    }
  }


}

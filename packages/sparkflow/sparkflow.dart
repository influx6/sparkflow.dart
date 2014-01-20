library sparkflow;

import 'dart:async';
import 'package:hub/hub.dart' as hub;
import 'package:streamable/streamable.dart';
import 'package:ds/ds.dart' as ds;
import 'package:statemanager/statemanager.dart';


/*base class for flow */
abstract class FlowAbstract{
	void boot();
	void shutdown();
	void freeze();
}

abstract class FlowSocket{
	void beginGroup();
	void endGroup();
	void send();
	void close();
}

/*base class for ports*/
abstract class FlowPort{
  void connect();
  void data(data);
  void beginGroup(data);
  void endGroup(data);
  void disconnect();

}

abstract class FlowComponent{
  final alias = new hub.MapDecorator();
  final metas = new hub.MapDecorator.from({'desc':'basic description'});
  final ports = new hub.MapDecorator();

  FlowComponent(id){
    this.metas.add('id',id);
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

  dynamic meta(id,[val]){
    if(val != null && !this.metas.has(id)) this.metas.add(id,val);
    if(val != null && this.metas.has(id)) this.metas.update(id,val);
    return this.metas.get(id); 
  }
  
  void removeMeta(id){
    this.metas.destroy(id);
  }

  String get description => this.metas.get('desc');
  void set description(String desc){ this.metas.update('desc',desc); }
  String get id => this.metas.get('id');
  void set id(String id){ this.metas.update('id',id); }

}

//base class for IP (Information Packets)
abstract class FlowIP{
  dynamic get data;
  dynamic get id;
  dynamic get meta;
}

abstract class FlowNetwork{
  final metas = new hub.MapDecorator.from({'desc':'Sparkflow Network Graph'});


  FlowNetwork(String id){
    this.metas.add('id',id);
  }

  void add(FlowComponent n,[String uniq]);
  void remove(String n);
  void connect(String m,String mport,String n,String nport);
  void disconnect(String m,String n);

  String get id => this.metas.get('id');
  void set id(String id){ this.metas.update('id',id); }
}

class SocketStream{
  final String uuid = hub.Hub.randomString(3);
  final meta = new hub.MapDecorator();
  final Streamable data = Streamable.create();  
  final Streamable end = Streamable.create();  
  final Streamable begin = Streamable.create();
  StateManager state;
  StateManager delimited;
  Streamable stream;
   
  static create() => new SocketStream();
  
  SocketStream(){
    this.state = StateManager.create(this);
    this.delimited = StateManager.create(this);
    
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
      if(!this.state.ready()) this.data.resume();
      this.state.switchState("lock");
      this.data.pause();
    });
    
    this.end.initd.on((n){
      this.data.resume();
      this.state.switchState("unlock");
    });
    
    this.stream = MixedStreams.combineUnOrder([begin,data,end])((tg,cg){
      return this.state.ready();
    },null,(cur,mix,streams,ij){   
      if(this.delimited.allowed()) return mix.emit(cur.join(this.meta.get('delimiter')));
      return mix.emitMass(cur);
    });
    
    this.setDelimiter('/');
    this.delimited.switchState("no");
    this.state.switchState("unlock");
  }
  
  dynamic get dataTransformer => this.data.transformer;
  dynamic get endGroupTransformer => this.end.transformer;
  dynamic get beginGroupTransformer => this.begin.transformer;
  dynamic get streamTransformer => this.stream.transformer;

  dynamic get dataDrained => this.data.drained;
  dynamic get endGroupDrained => this.end.drained;
  dynamic get beginGroupDrained => this.begin.drained;
  dynamic get streamDrained => this.stream.drained;
  
  dynamic get dataClosed => this.data.closed;
  dynamic get endGroupClosed => this.end.closed;
  dynamic get beginGroupClosed => this.begin.closed;
  dynamic get streamClosed => this.stream.closed;

  void whenDrained(Function n){
    this.stream.whenDrained(n);  
  }
  
  void whenClosed(Function n){
    this.stream.whenClosed(n);  
  }
  
  void whenInitd(Function n){
    this.stream.whenInitd(n);  
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

  bool get hasConnections => this.stream.hasListeners;
}

final socketFilter = (i,n){
  var socks = i.current;
  if(socks.socket != null && socks.socket == n) return true;
  return false;
};

final portFilter = (i,n){
  var socks = i.current;
  if(socks.port != null && socks.port == n) return true;
  //if(socks.socket.port != null && socks.socket.port == n) return true;
  if(socks.socket.from != null && socks.socket.from == n) return true;
  if(socks.socket.to != null && socks.socket.to == n) return true;
  return false;
};

class Socket extends FlowSocket{
  final Distributor continued = Distributor.create('streamable-streamcontinue');
  final Distributor halted = Distributor.create('streamable-streamhalt');
  final String uuid = hub.Hub.randomString(5);
  final ds.dsList subscribers = ds.dsList.create();
  SocketStream streams;
  FlowPort from,to;
  var filter;
	
  static create([from]) => new Socket(from);
  
  Socket([from]){
    this.streams = SocketStream.create();
    this.filter = this.subscribers.iterator;
    if(from != null) this.attachFrom(from);
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
  
  dynamic on(Function n){
    this.streams.stream.on(n);
  }

  dynamic off(Function n){
    this.streams.stream.off(n);
  }

  void detachAll(){
    var handle = this.subscribers.iterator;
    while(handle.moveNext()){
      handle.current.close();
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
    sub.port = a;
    return sub;
  }

  dynamic detachPort(FlowPort a){
    var sock = this.filter.remove(a,null,portFilter).data;
    if(sock == null) return null;
    if(sock.socket != null) sock.socket = null;
    if(sock.port != null) sock.port = null;
    sock.close(true);
    return sock;
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
    var sub = this.streams.stream.subscribe(a.send);
    sub.socket = a;
    this.subscribers.add(sub);
    return sub;
  }
  
  dynamic unbindSocket(Socket a){
    if(!this.filter.has(a,socketFilter)) return null;
    var sub = this.filter.remove(a,null,socketFilter).data;
    if(sub.socket != null) sub.socket = null;
    //if(sub.port != null) sub.port = null;
    sub.close(true);
    return sub;
  }
  
  bool boundedToPort(FlowPort a){
    return this.filter.has(a,portFilter);
  }

  bool boundedToSocket(FlowSocket a){
    return this.filter.has(a,socketFilter);
  }

  void connect(){
    this.streams.stream.resume();
    this.continued.emit(true);
  }
  
  void disconnect(){
    this.streams.stream.pause();
    this.halted.emit(true);
  }

  void beginGroup([group]){
    this.streams.begin.emit(group);
  }

  void endGroup([group]){
    this.streams.end.emit(group);
  }
  
  void send(data){
    this.streams.data.emit(data);
  }

  void end(){
    this.detachAll();
    //if(this.from) this.from.socket.unbindSocket(this);
    if(this.to != null) this.unbindSocket(this.to.socket);
    this.from = this.to = null;
    this.streams.close();
  }

  void close() => this.end();

  bool get isConnected => this.streams.stream.streamResumed;
  bool get isDisconnected => this.streams.stream.streamPaused;

}

//filters of socket subscribers with aliases
final aliasFilterFn = (it,n){
  if(it.current.alias == n) return true;
  return false;
};

/*the channel for IP transmission on a component*/
class Port extends FlowPort{
  final String uuid = hub.Hub.randomString(5);
  hub.Counter counter;
  Map aliases = new Map();
  FlowSocket socket;
  dynamic aliasFilter;
  hub.Mutator _egtransformer,_bgtransformer,_dttransformer;
  String id,componentID;
  
  static create(id,[cid]) => new Port(id,cid);

  Port(this.id,[cid]):super(){
    this.componentID = cid;
    this.counter = hub.Counter.create(this);
    this.socket = Socket.create(this);
    this.aliasFilter = socket.subscribers.iterator;

    this._egtransformer = this.endGroupStream.cloneTransformer();
    this._bgtransformer = this.beginGroupStream.cloneTransformer();
    this._dttransformer = this.dataStream.cloneTransformer();
  }

  bool get hasConnections => this.socket.hasConnections;

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
    this.checkAliases();
    var sub = this.socket.attachPort(a);
    if(sub == null) return null;
    this.counter.tick();
    var id = (alias == null ? this.counter.counter : alias).toString();
    sub.alias = id;
    this.aliases[id]= sub;
    return sub;

  }

  dynamic bindSocket(Socket v,[String alias]){
    this.checkAliases();
    var sub = this.socket.bindSocket(v);
    if(sub == null) return null;
    var id = (alias == null ? this.counter.tick() : alias).toString();
    sub.alias = id;
    this.aliases[id]= sub;
    return sub;
  }
  
  dynamic unbindPort(FlowPort a){
    this.checkAliases();
    var sub = this.socket.detachPort(a);
    if(sub == null) return null;
    this.removeSocketAlias(sub.alias);
    sub.env.suppressErrors();
    if(sub.alias != null) sub.alias = null;
    sub.env.unsuppressErrors();
    sub.closeAttributes();
    return sub;
  }

  dynamic unbindSocket(Socket v){
    this.checkAliases();
    var sub = this.socket.unbindSocket(v);
    if(sub == null) return null;
    this.removeSocketAlias(sub.alias);
    sub.env.suppressErrors();
    if(sub.alias != null) sub.alias = null;
    sub.env.unsuppressErrors();
    sub.closeAttributes();
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
      if(e.socket == v){
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
        this._bgtransformer.whenDone(sub.socket.beginGroup);
        this._bgtransformer.emit(data);
      }      
      return;
    }
    this.socket.beginGroup(data);
  }

  void send(data,[String alias]){
    if(alias != null){
      this._updatePortTransformerClones();
      var sub = this.getSocketAlias(alias);
      if(sub != null){
        this._dttransformer.whenDone(sub.socket.send);
        this._dttransformer.emit(data);
      }
      return;
    }
    this.socket.send(data);
  }

  void endGroup(data,[String alias]){
    if(alias != null){
      this._updatePortTransformerClones();
      var sub = this.getSocketAlias(alias);
      if(sub != null){
        this._egtransformer.whenDone(sub.socket.endGroup);
        this._egtransformer.emit(data);
      }   
      return;
    }
    this.socket.endGroup(data);
  }
  
  void tap(Function n){
    this.socket.on(n);
  }

  void untap(Function n){
    this.socket.off(n);
  }

  void connect(){
    if(this.socket == null) return;
    this.socket.connect();
  }

  void disconnect(){
    if(this.socket == null) return;
    this.socket.disconnect();
  }

  bool get isConnected{
    return this.socket.isConnected;
  }

  bool get isDisconnected {
    this.socket.isDisconnected; 
  }
  
  void close(){
    this.socket.close();
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

class Network extends FlowNetwork{
  //global futures of freze,boot,shutdown
  Future _whenAlive,_whenFrozen,_whenDead;
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
  // map of uuid registers with either unique names or uuid
  final uuidRegister = new hub.MapDecorator();
  //uuid of network
  final String uuid = hub.Hub.randomString(5);
  //final outport for the particular network,optionally usable
  final Port nout = Port.create('networkOutport');
  //final inport for the particular network,optionally usable
  final Port nin = Port.create('networkInport');
  // the error stream
  final errorStream = Port.create('networkError');
  // the info stream
  final infoStream = Port.create('networkInfo');
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
   this.stateManager = StateManager.create(this);

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
  }
  
  void lockNetworkStreams(){
    this.nout.disconnect();
    this.nin.disconnect();
    this.errorStream.disconnect();
    this.infoStream.disconnect();
  }

  void unlockNetworkStreams(){
    this.nout.connect();
    this.nin.connect();
    this.errorStream.connect();
    this.infoStream.connect();
  }

  void closeNetworkStreams(){
    this.nout.close();
    this.nin.close();
    this.errorStream.close();
    this.infoStream.close();
  }

  Future get whenAlive => this._whenAlive;
  Future get whenDead => this._whenDead;
  Future get whenFrozen => this._whenFrozen;

  Future filter(String m,[bool bf]){
    var bff = (bf == null ? false : bf);
    if(!!bff) return this.filterBF(m);
    return this.filterDF(m);
  }

  Future filterDF(String m){
    var id = this.uuidRegister.get(m);
    if(id == null) return null;
    return this.dfFilter.filter(id).then((_){
      return _;
    }).catchError((e){ 
      this.errorStream.send({ 'type':"filterDF", 'alias': m, 'uuid': id, 'error': e});
    });
  }

  Future filterBF(String m){
    var id = this.uuidRegister.get(m);
    if(id == null) return null;
    return this.bfFilter.filter(id).then((_){
      return _;
    }).catchError((e){ 
      this.errorStream.send({ 'type':"filterBF", 'alias': m, 'uuid': id, 'error': e});
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
    this.infoStream.send({ 'message':'adding iip socket for $id','type':"addIIPSocket", 'alias':id,'for': component.UID });
    return iip;
  }

  dynamic removeIIPSocket(alias,[Function n]){
    if(!this.uuidRegister.has(alias)) return null;
    var id = this.uuidRegister.get(alias);
    if(id == null) return null;
    var sock =  this.IIPSocketFilter.remove(id,IIPFilter);
    if(n != null) fn(sock);
    sock.selfDestruct();
    this.infoStream.send({ 'type':"removeIIPSocket", 'alias':alias,'for': component.UID });
    return sock;
  }

  dynamic addInitial(alias,data){
    if(!this.uuidRegister.has(alias)) return null;

    if(this.isDead || this.isFozen){
        this.infoStream.send({ 'type':"addInitialPacket", 'alias':alias });
        return this.IIPackets.add({ 'uuid': alias, 'data': data});
    }

    var socket = this.filterIIPSocket(alias);
    if(socket != null) socket['socket'].send(data);

    this.infoStream.send({ 'type':"addInitialPacket", 'alias':alias });
    return socket;
  }

  dynamic removeInitial(alias,[Function n]){
    if(!this.uuidRegister.has(alias) || this.isAlive) return null;

    var data,uuid = this.uuidRegister.get(alias);
    data = this.iipDataIterator.remove(uuid,IIPDataFilter);
    if(n != null) n(data);
    this.infoStream.send({ 'type':"removeInitialPacket", 'alias':alias });
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
 
    this.infoStream.send({ 'type':"sendInitials", 'message': 'sending out all initials' });
  }

  dynamic add(FlowComponent a,String id,[Function n]){
    var node = this.components.add(a);
    this.components.bind(this.placeholder,node,0);
    this.components.bind(node,this.placeholder,1);
    this.uuidRegister.add(id,a.uuid);
    this.addIIPSocket(a,id,n);
    this.infoStream.send({ 'type':"addComponent", 'message': 'adding new component','uuid': a.UID, 'alias':id });
    return node;
  }

  dynamic remove(String a,[Function n,bool bf]){
    if(!this.uuidRegister.has(a)) return;

    var comso = this.filter(a,bf);
    this.comso.then((_){
      if(n != null) n(_);
      _.data.detach();
      this.components.eject(_);
      this.infoStream.send({ 'type':"removeComponent", 'message': 'remove component','uuid': _.data.UID, 'alias':a });
    }).catchError((e){
      this.errorStream.send({'type':'network-remove', 'error': e, 'component': a });
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
          this.components.bind(from,to,2);
          this.infoStream.send({ 'type':"connectComponent", 'from': a, 'to': b,'message': 'connecting two component','uuid':'','alias':''});
          return _;
        }).catchError((e){
          this.errorStream.send({'type':'network-connect', 'error': e, 'from': a, 'to': b});
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
        this.components.unbind(from,to,2);
        this.infoStream.send({ 'type':"disconnectComponent", 'from': a, 'to': b,'message': 'connecting two component','uuid':'','alias':''});
        return _;
      }).catchError((e){
        this.errorStream.send({'type':'network-disconnect', 'error': e, 'from': a, 'to': b});
      });
    };

    this.disconnectionsCompiler.add(wait);
    return this;
  }
  
  Future linkOut(String com,String comport,[bool bf]){
   return this.filter(com,bf).then((_){
      _.data.getPort(comport).bindPort(this.nout);
    });
  }
  
  Future linkIn(String com,String inport,[bool bf]){
    return this.filter(com,bf).then((_){
     this.nin.unbindPort(_.data.getPort(inport));    
    });
  }

  Future freeze(){
    if(this.isFrozen && this._whenFrozen != null) return this.whenFrozen;

    var completer = new Completer();
    this._whenFrozen = this.connectionsCompiler.whenComplete((_){

      if(this.isFrozen || this.isDead){
         completer.complete(this);
         return completer.future;
      }

      this.components.cascade((it){
          if(it.current.data == this.placeholder.data) return;
          it.current.data.freeze();
      },(it){
        completer.complete(this);
      });

      this.stateManager.switchState('frozen');
      this.infoStream.send({ 'type':"freezeNetwork", 'message': 'freezing/pausing network operations'});
      this.lockNetworkStreams();
      return completer.future;
    });

    return this.whenFrozen;
  }

  Future shutdown(){
    if(this.isDead && this._whenDead != null) return this.whenDead;

    var completer = new Completer();
    this._whenDead = this.disconnectionsCompiler.whenComplete((_){

        if(this.isDead){
         completer.complete(this);
         return completer.future;
        }

        this.components.cascade((it){
            if(it.current.data == this.placeholder.data) return;
            it.current.data.shutdown();
        },(it){
          completer.complete(this);
        });
        this.stateManager.switchState('dead');
        this.infoStream.send({ 'type':"shutdownNetwork", 'message': 'shutting down/killing network operations'});
        this.stopStamp = new DateTime.now();

        return completer.future;
    });

    return this.whenDead;
  }

  Future boot(){
    if(this.isAlive && this._whenAlive != null) return this.whenAlive;

    var completer = new Completer();
    this._whenAlive = this.connectionsCompiler.whenComplete((_){

      if(this.isAlive){
         completer.complete(this);
         return completer.future;
      }

      if(this.isFrozen || this.isDead){
        this.components.cascade((it){
          if(it.current.data == this.placeholder.data) return;
          it.current.data.boot();
        },(it){
          completer.complete(this);
        });
      }
      this.sendInitials();
      this.stateManager.switchState('alive');
      this.infoStream.send({ 'type':"bootingNetwork", 'message': 'booting network operations'});
      this.unlockNetworkStreams();
      this.startStamp = new DateTime.now();

      return completer.future;
    });

    return (future == null ? new Future.value(true) : future);
  }


  bool get isAlive{
    return this.stateManager.alive();
  }

  bool get isFrozen{
    return this.stateManager.frozen();
  }

  bool get isDead{
    return this.stateManager.dead();
  }

  dynamic UUID(String id){
    return this.uuidRegister.get(id);
  }

  dynamic hasUUID(String id){
    return this.uuidRegister.has(id);
  }

  String get UID => this.metas.get('id')+'#'+this.metas.get('uuid');
  
  bool get isEmpty => this.graph.isEmpty;
}

/*class for component*/
class Component extends FlowComponent{
  final String uuid = hub.Hub.randomString(7);
  var network;

  
  static create([String id]) => new Component(id);

  Component([String id]): super((id == null ? 'Component' : id)){
    this.network = Network.create(this.id+'-Subnet');

    this.ports.add('option',Port.create('option',this.id));
    this.ports.add('in',Port.create('in',this.id));
    this.ports.add('err',Port.create('err',this.id));
    this.ports.add('out',Port.create('out',this.id));

    this.alias.add('in','in');
    this.alias.add('out','out');
    this.alias.add('option','option');

    this.metas.add('uuid',this.uuid);
  }
  
  Future boot(){
    this.ports.onAll((k,n){
       n.connect();
    });
    return this.network.boot();
  }

  Future freeze(){
    this.ports.onAll((k,n){
       n.disconnect();
    });   
    return this.network.freeze();
  }

  Future shutdown(){
    this.ports.onAll((k,n){
       n.close();
    });
    return this.network.shutdown();
  }

  dynamic bind(String myport,Component component,String toport,[String mysocketId]){
    if(!this.hasPort(myport) || !component.hasPort(toport)) return null;

    var myPort = this.port(myport),
          toPort = component.port(toport);

    return toPort.bindPort(myPort,mysocketId);
  }

  dynamic unbind(String myport,Component component,String toport,[String mysocketId]){
    if(!this.hasPort(myport) || !component.hasPort(toport)) return null;

    var myPort = this.port(myport),
          toPort = component.port(toport);

    return toPort.unbindPort(myPort);
  }

  FlowPort makePort(String id,[Port p,bool override]){
    if(this.alias.has(id) && (!override || override == null)) return null;
    var port = (p == null ? Port.create(id,this.id) : p);
    if(override != null && !!override) this.ports.update(this.alias.get(id),port);
    else{
      this.alias.add(id,id);
      this.ports.add(this.alias.get(id),port);
    }
    return this.ports.get(this.alias.get(id));
  }
  
  
  void close(){
    this.ports.onAll((n) => n.detach());
  }
  
  void unloopPorts(String v,String u){
    var from = this.port(v);
    var to = this.port(u);

    if(to != null && from != null){
      from.unbindPort(to);
    }
  }

  void loopPorts(String v,String u){
    var from = this.port(v);
    var to = this.port(u);

    if(to != null && from != null){
      from.bindPort(to);
    }
  }

  String get UID => this.metas.get('id')+'#'+this.metas.get('uuid');

}

class SparkFlow extends FlowAbstract{
  final metas = new hub.MapDecorator.from({'desc':'top level flowobject'});
  final Network network;
  var tree = new hub.MapDecorator();

  static create(String id,[String desc]) => new SparkFlow(id,desc);

  SparkFlow(String id,[String desc]): network = Network.create(id){
    this.metas.add('id',id);
    if(desc != null) this.metas.add('desc',desc);
  }

  void add(String alias,Component a){
    if(this.tree.has(alias)) throw "Alias $alias is already used";
    this.tree.add(alias,a);
  }

  void remove(String alias){
    if(!this.tree.has(alias)) return;
    this.unUse(alias);
    this.tree.destroy(alias);
  }

  void use(String alias,[Function n]){
    if(!this.tree.has(alias)) return;
    this.network.add(this.tree.get(alias),alias,n);
  }

  void unUse(String alias,[Function n]){
    if(!this.tree.has(alias)) return;
    this.network.remove(this.tree.get(alias),alias,n);
  }

  Future boot(){
    return this.network.boot();
  }

  Future freeze(){
    return this.network.freeze();
  }

  Future shutdown(){
    return this.network.shutdown();
  }

  bool get isAlive => this.network.isAlive;
  bool get isDead => this.network.isDead;
  bool get isFrozen => this.network.isFrozen;

  String get id => this.metas.get('id');
  String get desc => this.metas.get('desc');

}

class MassTree extends hub.MapDecorator{
  final canDestroy = hub.Switch.create();

  static create() => new MassTree();

  MassTree();


  dynamic destroy(String key){
    if(!this.canDestroy.on()) return null;
    return super.destroy(key);
  }

}


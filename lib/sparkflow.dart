library sparkflow;

import 'dart:async';
import 'package:hub/hub.dart' as hub;
import 'package:streamable/streamable.dart';
import 'package:ds/ds.dart' as ds;

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
  void untap(String n,Function m);
  void untapOnce(String n,Function m);
  void tap(String n,Function m);
  void tapOnce(String n,Function m);
  void forceCondition(Function n);
  void forceBGCondition(Function n);
  void forceEGCondition(Function n);
  void flushPackets();
  
}

abstract class FlowComponentAbstract{
      
  hub.MapDecorator get sd;
  FlowNetwork get belongsTo;
  void set belongsTo(FlowNetwork n);
  String get UID;
  void removeMeta(id);
  void setGroup(String g);
  String get description;
  void set description(String desc);
  String get id;
  String get group;
  String get componentClassID;
  void set id(String id);
  Function get mutator;
  bool get hasMutator;
  void set mutator(Function n);
  dynamic mutate(Function n);
  dynamic meta(id,[val]);

}


abstract class FlowNetworkAbstract{
  void useComponent(FlowComponent n,String uniq);
  void use(String n,String m);
  void remove(String n);
  void connect(String m,String mport,String n,String nport);
  void disconnect(String m,String n,String j,String k);
  String get id;
  void set id(String id);
  FlowComponent get belongsTo;
  void set belongsTo(FlowComponent n);
}

class FlowNetwork extends FlowNetworkAbstract{
  final metas = new hub.MapDecorator.from({'desc':'Sparkflow Network Graph'});
  var _parent;

  FlowNetwork(String id){
    this.metas.add('id',id);
  }

  String get id => this.metas.get('id');
  void set id(String id){ this.metas.update('id',id); }
  
  FlowComponent get belongsTo => this._parent;
  void set belongsTo(FlowComponent n){ this._parent = n; }
  
  void useComponent(FlowComponent n,String uniq){ throw "Implement this"; }
  void use(String n,String m){throw "Implement this";}
  void remove(String n){throw "Implement this";}
  void connect(String m,String mport,String n,String nport){throw "Implement this";}
  void disconnect(String m,String n,String j,String k){throw "Implement this";}
}

class FlowComponent extends FlowComponentAbstract{
  final String uuid = hub.Hub.randomString(7);
  final metas = new hub.MapDecorator.from({'desc':'basic description'});
  final bindMeta = new hub.MapDecorator();
  final assocMeta = new hub.MapDecorator();
  final sharedData = new hub.MapDecorator();
  Function _mutator;

  FlowComponent(id){
    this.metas.add('id',id);
    this.metas.add('uuid',this.uuid);
    this.metas.add('group','components/$id');
    this.assocMeta.add('parent',null);
    if(this.hasMutator) this.mutator(this);
  }
      
  hub.MapDecorator get sd => this.sharedData;
  FlowNetwork get belongsTo => this.assocMeta.get('parent');
  void set belongsTo(FlowNetwork n) => this.assocMeta.update('parent',n);
  String get UID => this.metas.get('id')+'#'+this.metas.get('uuid');
  void removeMeta(id) => this.metas.destroy(id);
  void setGroup(String g) => this.metas.update('group',g);
  String get description => this.metas.get('desc');
  void set description(String desc) => this.metas.update('desc',desc); 
  String get id => this.metas.get('id');
  String get group => this.metas.get('group');
  String get componentClassID => this.group+"/"+this.id;
  void set id(String id) => this.metas.update('id',id); 
  Function get mutator => this._mutator;
  bool get hasMutator => this._mutator != null;
  
  void set mutator(Function n){
    this._mutator = n;
    this.meta('_mutator',n);
  }

  dynamic mutate(Function n){
    this.mutator = n;
    return n(this);
  }

  dynamic meta(id,[val]){
    if(val != null && !this.metas.has(id)) this.metas.add(id,val);
    if(val != null && this.metas.has(id)) this.metas.update(id,val);
    return this.metas.get(id); 
  }

  Map get toMeta{
    return {};
  }

}

Function _nopacket = (){};

bool  socketFilter(i,n){
  var socks = i.current;
  if(socks.get('socket') == n) return true;
  return false;
}

//filters of socket subscribers with aliases
bool aliasFilterFn(it,n){
  if(it.current.info.get('alias') == n) return true;
  return false;
}

List splitPortMap(String path){
  var part = path.split(':');
  if(part.length <= 1) return null;
  return part;
}

List registryPathProcessor (String path){
    path = path.toLowerCase();
    var from = path.split('/');
    if(from.length < 3) return null;
    return from;
}

Function toIP(type,socket,packets){
  return (data){
    if(data is Packet) return data;
    var d = hub.Funcs.switchUnless(data,null);
    var packet = packets();
    var port = (socket.from == null ? null : socket.from.tag);
    var owner = ( port == null ? null : (socket.from.owner == null ? null : socket.from.owner.UID));
    packet.init(type,d,owner,port);
    return packet;
  };
}

class SocketStream<M>{
  final String uuid = hub.Hub.randomString(3);
  final meta = new hub.MapDecorator();
  final Streamable stream = new Streamable();  
   
  static create() => new SocketStream();
  
  SocketStream();

  Streamable throttle(int mss,[Function n]){
    var ms = MixedStreams.throttle(this.stream,mss);
    if(n != null) ms.on(n);
    return ms;
  }

  dynamic get streamTransformer => this.stream.transformer;

  dynamic get streamDrained => this.stream.drained;

  dynamic get streamInitd => this.stream.initd;

  dynamic get streamEnded => this.stream.ended;

  dynamic get streamClosed => this.stream.closed;

  dynamic get streamPaused => this.stream.pauser;

  dynamic get streamResumed => this.stream.resumer;

  dynamic metas(String key,[dynamic value]){
    if(value == null) return this.meta.get(key);
    this.meta.add(key,value);
  }
  
  void setMax(int n){
    this.stream.setMax(n);
  }
  
  void endStream() => this.stream.end();

  void close(){
    this.stream.close();
    this.meta.flush();
  }

  void flushPackets(){
    this.stream.forceFlush();
  }

  void enableEndStreamEvent(){
    this.stream.enableEndOnDrain();
  }

  void disableEndStreamEvent(){
    this.stream.disableEndOnDrain();
  }

}

class Socket<M> extends FlowSocket{

  var _headerPackets = () => Packet.create();
  var _dataPackets = () => new Packet<M>();

  final Distributor continued = Distributor.create('streamable-streamcontinue');
  final Distributor halted = Distributor.create('streamable-streamhalt');
  final String uuid = hub.Hub.randomString(5);
  final subscribers = ds.dsList.create();
  final Distributor onSocketSubscription = Distributor.create('streamable-socketsub');
  final Distributor onSocketRemoval = Distributor.create('streamable-socketUnsub');

  hub.Condition bgconditions,egconditions,dtconditions;
  /* hub.Counter counter; */
  Function toBGIP,toEGIP,toDataIP;
  SocketStream streams;
  FlowPort from,to;
  var filter;

  
  static create([from]) => new Socket(from);
  
  Socket([from]){
    this.toBGIP = toIP('beginGroup',this,this._headerPackets);
    this.toEGIP = toIP('endGroup',this,this._headerPackets);
    this.toDataIP = toIP('data',this,this._dataPackets);
    this.streams = new SocketStream();
    this.filter = this.subscribers.iterator;
    /* this.counter = new hub.Counter(this); */

    this.dtconditions = hub.Hub.createCondition('data-conditions');
    this.bgconditions = hub.Hub.createCondition('begingroup-conditions');
    this.egconditions = hub.Hub.createCondition('endgroup-conditions');

    if(from != null) this.attachFrom(from);

    this.dtconditions.whenDone(this.mixedStream.emit);
    this.bgconditions.whenDone(this.mixedStream.emit);
    this.egconditions.whenDone(this.mixedStream.emit);

    /*this.enableEndStreamEvent();*/
  }
 
  dynamic throttle(ms,[n]) => this.streams.throttle(ms,n);

  void enableEndOnDrainEvent(){
    this.streams.enableEndStreamEvent();
  }

  void disableEndOnDrainEvent(){
    this.streams.disableEndStreamEvent();
  }

  void forcePacketCondition(bool n(dynamic r)){
    this.dtconditions.on(n);
  }
  
  void forceBGPacketCondition(bool n(dynamic r)){
    this.bgconditions.on(n);
  }

  void forceEGPacketCondition(bool n(dynamic r)){
    this.egconditions.on(n);
  }

  void forceCondition(bool n(dynamic r)){
    this.dtconditions.on((d){
      return n(d.data);
    });
  }
  
  void forceBGCondition(bool n(dynamic r)){
    this.bgconditions.on((d){
      return n(d.data);
    });
  }

  void forceEGCondition(bool n(dynamic r)){
    this.egconditions.on((d){
      return n(d.data);
    });
  }

  void flushDataConditions() => this.dtconditions.clearConditions();
  void flushBGConditions() => this.bgconditions.clearConditions();
  void flushEGConditions() => this.egconditions.clearConditions();

  void flushAllConditions(){
    this.flushDataConditions();
    this.flushEGConditions();
    this.flushBGConditions();
  }

  void send(packet){
    var pack = this.toDataIP(packet);
    this.dtconditions.emit(pack);
  }

  void endGroup(packet){
    var pack = this.toEGIP(packet);
    this.egconditions.emit(pack);
  }

  void beginGroup(packet){
    var pack = this.toBGIP(packet);
    this.bgconditions.emit(pack);
  }

  void setMax(int m){
    this.streams.setMax(m);  
  }
  
  void flushPackets(){
    this.streams.flushPackets();
  }

  dynamic get mixedStream => this.streams.stream;
  
  dynamic get mixedTransformer => this.streams.streamTransformer;
  
  dynamic get mixedEnded => this.streams.streamEnded;

  dynamic get mixedClosed => this.streams.streamClosed;

  dynamic get mixedDrained => this.streams.streamDrained;

  dynamic get mixedInitd => this.streams.streamInitd;

  dynamic get mixedPaused => this.streams.streamPaused;

  dynamic get mixedResumed => this.streams.streamResumed;

  void enableFlushing(){
    this.mixedStream.enableFlushing();
  }

  void disableFlushing(){
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

  dynamic on(Function n){
      return this.mixedStream.on(n);
  }

  dynamic off(Function n){
      return this.mixedStream.off(n);
  }

  dynamic onOnce(Function n){
    return this.mixedStream.onOnce(n);
  }

  dynamic offOnce(Function n){
    return this.mixedStream.offOnce(n);
  }

  dynamic onEnd(Function n){
    this.mixedEnded.on(n);
  }

  dynamic onEndOnce(Function n){
    this.mixedEnded.onOnce(n);
  }

  dynamic offEnd(Function n){
    this.mixedEnded.off(n);
  }

  dynamic offEndOnce(Function n){
    this.mixedEnded.offOnce(n);
  }

  void detachAll(){
    var sub,handle = this.subscribers.iterator;
    while(handle.moveNext()){
      sub = handle.current;
      this.onSocketRemoval.emit(sub);
      sub.get('stream').close();
      sub.destroy('socket');
      sub.destroy('port');
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
  
  void attachTo(FlowPort to,[bool bindEnding]){
    if(to != null) return;
    this.to = to;
    this.bindSocket(to.socket,bindEnding);
  }
  
  dynamic attachPort(FlowPort a,[bool bindEnding]){
    var sub = this.bindSocket(a.socket,bindEnding);
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

  void whenSocketSubscribe(Function n){
    this.onSocketSubscription.on(n);
  }

  void whenSocketUnsubscribe(Function n){
    this.onSocketRemoval.on(n);
  }

  void clearSubscriptionWatchers() => this.onSocketSubscription.free();
  void clearUnsubscriptionWatchers() => this.onSocketRemoval.free();
  void clearAllSubscriptionWatchers() => this.clearSubscriptionWatchers() && this.clearUnsubscriptionWatchers();

  dynamic bindSocket(Socket a,[bool bindEnding]){
    if(this.filter.has(a,socketFilter)) return null;
    bindEnding = hub.Funcs.switchUnless(bindEnding,true);
    var sub = hub.Hub.createMapDecorator();
    sub.add('socket',a);
    sub.add('stream',this.mixedStream.subscribe(a.send));
    this.subscribers.add(sub);
    a.mixedStream.whenClosed(sub.get('stream').close);
    if(bindEnding) sub.get('stream').whenEnded(a.endStream);
    this.onSocketSubscription.emit(sub);
    return sub;
  }
  
  dynamic unbindSocket(Socket a){
    if(!this.filter.has(a,socketFilter)) return null;
    var sub = this.filter.remove(a,null,socketFilter).data;
    this.onSocketRemoval.emit(sub);
    sub.get('stream').close();
    sub.destroy('socket');
    sub.destroy('port');
    return sub;
  }
  
  void resume(){
    this.mixedStream.resume();
    this.continued.emit(true);
  }
  
  void pause(){
    this.mixedStream.pause();
    this.halted.emit(true);
  }

  void endStream([n]){
    this.streams.endStream();
  }

  void end(){
    this.detachAll();
    this.streams.close();
    this.from = this.to = null;
  }

  void close() => this.end();
  
  num get streamSize => this.mixedStream.streams.size;
  num get totalSocketSubscribers => this.subscribers.size;
  bool get hasSocketSubscribers => !this.subscribers.isEmpty;
  bool get hasConnections => this.mixedStream.hasListeners;
  bool get isResumed => this.mixedStream.streamResumed;
  bool get isPaused => this.mixedStream.streamPaused;

  bool get isConnected => this.isResumed;
  bool get isDisconnected => this.isPaused;
  
  void connect() => this.resume();
  void disconnect() => this.pause();
}

/*the channel for IP transmission on a component*/
class Port<M> extends FlowPort<M>{
  final String uuid = hub.Hub.randomString(5);
  final Map aliases = new Map();
  hub.Counter counter;
  hub.MapDecorator meta;
  FlowComponent owner;
  Socket socket;
  dynamic aliasFilter;
  hub.Mutator _transformer;
  
  static create(id,m,[com]) => new Port(id,m,com);

  Port(String id,Map meta,[this.owner]):super(){
    this.meta = new hub.MapDecorator.from(hub.Funcs.switchUnless(meta,{}));
    this.counter = hub.Counter.create(this);
    this.socket = new Socket(this);
    this.aliasFilter = socket.subscribers.iterator;
    this._transformer = this.mixedStream.cloneTransformer();
    this.meta.update('group','nogroup');
    this.meta.update('id',id);
  }
    
  dynamic throttle(ms,[n]) => this.socket.throttle(ms,n);

  void endStream() => this.socket.endStream();

  void enableEndOnDrainEvent(){
    this.socket.enableEndOnDrainEvent();
  }

  void disableEndOnDrainEvent(){
    this.socket.disableEndOnDrainEvent();
  }

  Packet createDataPacket(dynamic n){
    return this.socket.toDataIP(n);
  }

  Packet createEGPacket(dynamic n){
    return this.socket.toEGIP(n);
  }

  Packet createBGPacket(dynamic n){
    return this.socket.toBGIP(n);
  }

  void renamePort(String name){
    this.meta.update('id',name);
  }

  String get id => this.meta.get('id');
  String get tag{
    return (this.meta.get("group")+":"+id);
  }
  

  dynamic get mixedStream => this.socket.mixedStream;
  
  dynamic get mixedTransformer => this.socket.mixedTransformer;
  
  dynamic get mixedDrained => this.socket.mixedDrained;

  dynamic get mixedClosed => this.socket.mixedClosed;

  dynamic get mixedInitd => this.socket.mixedInitd;

  dynamic get mixedPaused => this.socket.mixedPaused;

  dynamic get mixedResumed => this.socket.mixedResumed;

  num get totalSocketSubscribers => this.socket.totalSocketSubscribers;
  bool get hasConnections => this.socket.hasConnections;
  bool get hasSubscribers => !this.socket.hasSocketSubscribers;
  num get streamSize => this.socket.streamSize;

  void forcePacketCondition(n) => this.socket.forcePacketCondition(n);
  void forceBGPacketCondition(n) => this.socket.forceBGPacketCondition(n);
  void forceEGPacketCondition(n) => this.socket.forceEGPacketCondition(n);
  void forceCondition(n) => this.socket.forceCondition(n);
  void forceBGCondition(n) => this.socket.forceBGCondition(n);
  void forceEGCondition(n) => this.socket.forceEGCondition(n);

  void flushDataConditions() => this.socket.flushDataConditions();
  void flushBGConditions() => this.socket.flushBGConditions();
  void flushEGConditions() => this.socket.flushEGConditions();

  void flushAllConditions() => this.socket.flushAllConditions();

  dynamic handleType(String type,data,FlowSocket socket){
    if(hub.Valids.match(type,'data')) return socket.toDataIP(data);
    if(hub.Valids.match(type,'beginGroup')) return socket.toBGIP(data);
    if(hub.Valids.match(type,'endGroup')) return socket.toEGIP(data);
  }

  dynamic handleAliasCall(String type,FlowSocket socket){
    return (data){
      if(hub.Valids.match(type,'data')) return socket.send(data);
      if(hub.Valids.match(type,'beginGroup')) return socket.beginGroup(data);
      if(hub.Valids.match(type,'endGroup')) return socket.endGroup(data);
    };
  }

  void handlePacket(data,Function handler,String type,[String alias]){
    if(alias != null){
      this._updatePortTransformerClones();
      var sub = this.getSocketAlias(alias);
      if(sub != null){
        var socket = sub.get('socket');
        if(socket == null) return null;
        var d = this.handleType(type,data,socket);
        this._transformer.whenDone(this.handleAliasCall(type,socket));
        this._transformer.emit(d);
      }
      return null;
    }
    return handler(data);
  }

  void send(M data,[String alias]){
    this.handlePacket(data,(d){
      this.socket.send(d);
    },'data',alias);
  }

  void beginGroup([data,String alias]){
    var d = hub.Funcs.switchUnless(data,null);
    this.handlePacket(d,(r){
      this.socket.beginGroup(r);
    },'beginGroup',alias);
  }

  void endGroup([data,String alias]){
    var d = hub.Funcs.switchUnless(data,null);
    this.handlePacket(d,(r){
      this.socket.endGroup(r);
    },'endGroup',alias);
  }
  

  void tapEnd(Function n){
    return this.socket.onEnd(n);
  }

  void tapEndOnce(Function n){
    return this.socket.onEndOnce(n);
  }

  void untapEnd(Function n){
    return this.socket.offEnd(n);
  }

  void untapEndOnce(Function n){
    return this.socket.offEndOnce(n);
  }

  void tap(Function n){
    this.socket.on(n);
  }

  void tapSocketUnsubscription(Function n){
    this.socket.whenSocketUnsubscribe(n);
  }

  void tapSocketSubscription(Function n){
    this.socket.whenSocketSubscribe(n);
  }

  void tapData(Function n){
    this.socket.on((p){
      if(p is! Packet) p = this.createDataPacket(p);
      hub.Funcs.when(hub.Valids.match(p.event,'data'),(){
        return n(p);
      });
    });
  }

  void tapBeginGroup(Function n){
    this.socket.on((p){
      if(p is! Packet) p = this.createBGPacket(p);
      hub.Funcs.when(hub.Valids.match(p.event,'beginGroup'),(){
        return n(p);
      });
    });
  }

  void tapEndGroup(Function n){
    this.socket.on((p){
      if(p is! Packet) p = this.createEGPacket(p);
      hub.Funcs.when(hub.Valids.match(p.event,'endGroup'),(){
        return n(p);
      });
    });
  }

  void tapOnce(Function n){
    this.socket.onOnce(n);
  }

  void tapDataOnce(Function n){
    this.socket.onOnce((p){
      hub.Funcs.when(hub.Valids.match(p.event,'data'),(){
        return n(p);
      });
    });
  }

  void tapBeginGroupOnce(Function n){
    this.socket.onOnce((p){
      hub.Funcs.when(hub.Valids.match(p.event,'beginGroup'),(){
        return n(p);
      });
    });
  }

  void tapEndGroupOnce(Function n){
    this.socket.onOnce((p){
      hub.Funcs.when(hub.Valids.match(p.event,'endGroup'),(){
        return n(p);
      });
    });
  }

  void untap(Function n){
    this.socket.off(n);
  }

  void untapOnce(Function n){
    this.socket.offOnce(n);
  }

  void enableFlushing(){
    this.socket.enableFlushing();  
  }
  
  void disableFlushing(){
    this.socket.disableFlushing();  
  }

  void setMax(int m){
    this.socket.setMax(m);  
  }
  
  void unbindAll() => this.socket.detachAll();

  void _updatePortTransformerClones(){
    //clear the done list
    this._transformer.clearDone();
    //recheck if any change,then update if there is
    this._transformer.updateTransformerListFrom(this.mixedTransformer);
  }

  dynamic bindTo(FlowPort a,[bool bindend]){
    return this.socket.attachTo(a,bindend);
  }

  dynamic unbindTo(){
    return this.socket.detachTo();
  }

  dynamic bindPort(FlowPort a,[String alias,bool bindend]){
    return this.bindSocket(a.socket,alias,bindend);
  }

  dynamic bindSocket(Socket v,[String alias,bool bindend]){
    this.checkAliases();
    var sub = this.socket.bindSocket(v,bindend);
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
    // sub.flush();
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
      return fn(null);
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


  void resume(){
    if(this.socket == null) return null;
    this.socket.resume();
  }

  void pause(){
    if(this.socket == null) return null;
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
    this._transformer.clearDone();
  }

  void flushPackets(){
    this.socket.flushPackets();
  }

}

class InPortType{
  const InPortType();
  bool get isInport => true;
  bool get isOutport => false;
  String get name =>'Inport';
}

class OutportType{
  const OutportType();
  bool get isOutport => true;
  bool get isInport => false;
  String get name =>'Outport';
}

class ArrayPortType{
  const ArrayPortType();
  bool get isArrayPort => true;
  bool get isInport => false;
  bool get isOutport => false;
  String get name =>'Outport';
}

class Inport extends Port{
    final portType = const InPortType();
    
    static create(a,b,[c]) => new Inport(a,b,c);
    Inport(String id,Map m,[n]): super(id,m,n);

    String get portClass => this.portType.name;

}

class Outport extends Port{
    final portType = const OutportType();

    static create(a,b,[c]) => new Outport(a,b,c);
    Outport(String id,Map m,[n]): super(id,m,n);

    String get portClass => this.portType.name;
}

class _ArrayPort{
  final portType = const ArrayPortType();
  List<Port> ports;
  Map meta;
  String id;

  _ArrayPort(int total,String id,Map m){
     this.port = new List<Port>(total);
     this.id = id;
     this.meta = m;
  }

  String get portClass => this.portType.name;

  FlowPort getPort(int n){
    if(n > this.ports.length) return null;
    return this.ports.elementAt(n);
  }
}

class ArrayInport extends _ArrayPort{
   ArrayInport(int n,String id,Map m): super(n,id,m){
      hub.Funcs.cycle(n,(i){
        this.ports.add(Inport.create(i,{'desc':'$i indexed port'}));
      });
   }
}

class ArrayOutport extends _ArrayPort{
   ArrayOutport(int n,String id,Map m): super(n,id,m){
      hub.Funcs.cycle(n,(i){
        this.ports.add(Outport.create(i,{'desc':'$i indexed port'}));
      });
   }
}

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
  PortManager networkPorts;
  //global futures of freze,boot,shutdown
  Completer _whenAlive = new Completer(),_whenFrozen = new Completer(),_whenDead = new Completer();
  //parent for this network if its a subnet
  var _parent;
  //timestamps
  var startStamp,stopStamp;
  // iterator for the graph 
  var graphIterator, scheduledPacketsIterator,scheduledPacketsAlwaysIterator;
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

  // the network error stream
  final errorStream = Streamable.create();
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
  final scheduledPackets = ds.dsList.create();
  final scheduledPacketsAlways = ds.dsList.create();
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

  static create(id,[desc]) => new Network(id,desc);

  Network(id,[String desc]): super(id){
   this.networkPorts = PortManager.create(this);
   this.dfFilter.use(this.components);
   this.bfFilter.use(this.components);
   // this.graphIterator = this.components.iterator;
   this.scheduledPacketsIterator = this.scheduledPackets.iterator;
   this.scheduledPacketsAlwaysIterator = this.scheduledPacketsAlways.iterator;
   this.placeholder = this.components.add(PlaceHolder.create('placeholder',hub.Hub.randomString(7)));
   this.uuidRegister.add('placeholder',this.placeholder.data.uuid);
   this.stateManager = hub.StateManager.create(this);
  
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
   if(hub.Valids.exist(desc)) this.metas.add('description',desc);

   this.connectionStream.on((e){

     if(e['to'] == '*' && e['from'] != '*'){

         if(e['type'] == 'loop' || e['type'] == 'link'){
           this.connections.addConnection(e['toPort'],e['from'],e['fromPort'],e['socketid']);
         }

         if(e['type'] == 'unloop' || e['type'] == 'unlink'){
           this.connections.removeConnection(e['toPort'],e['from'],e['fromPort'],e['socketid']);
         }
     }

     if(e['from'] == '*' && e['to'] != '*'){

         if(e['type'] == 'loop' || e['type'] == 'link'){
           this.connections.addConnection(e['fromPort'],e['to'],e['toPort'],e['socketid']);
         }

         if(e['type'] == 'unloop' || e['type'] == 'unlink'){
           this.connections.removeConnection(e['fromPort'],e['to'],e['toPort'],e['socketid']);
         }
     }
     
   });


  }
  
  void createDefaultPorts(){
    this.createSpace('in');
    this.createSpace('out');
    this.createSpace('err');

    this.makeInport('in:in');
    this.makeOutport('out:out');
    this.makeOutport('err:err');
  }

  FlowPort port(String n) => this.networkPorts.port(n);
  
  dynamic createSpace(String sp){
    return this.networkPorts.createSpace(sp);
  }

  FlowPort makeOutport(String id,{ Map meta: null,Outport port:null }){
    return this.networkPorts.createOutport(id,meta:meta,port:port);
  }

  FlowPort makeInport(String id,{ Map meta: null,Inport port:null }){
    return this.networkPorts.createInport(id,meta:meta,port:port);
  }

  dynamic removePort(String path){
    return this.networkPorts.destroyPort(path);
  }

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
    this.networkPorts.pauseAll();
    this.errorStream.pause();
    this.connectionStream.pause();
    this.componentStream.pause();
    this.networkStream.pause();
  }

  void unlockNetworkStreams(){
    this.networkPorts.resumeAll();
    this.errorStream.resume();
    this.connectionStream.resume();
    this.componentStream.resume();
    this.networkStream.resume();
  }

  void closeNetworkStreams(){
    this.networkPorts.close();
    this.errorStream.close();
    this.connectionStream.close();
    this.componentStream.close();
    this.networkStream.close();
  }

  Future get whenAlive => this._whenAlive.future;
  Future get whenDead => this._whenDead.future;
  Future get whenFrozen => this._whenFrozen.future;

  Future filter(String m,[bool bf]) => this.filterComponent(m,bf);

  Future filterComponent(String m,[bool bf]){
    return this.filterNode(m,bf).then((_) => _.data);
  }

  Future filterNode(String m,[bool bf]){
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

  void alwaysSchedulePacket(String id,String port,dynamic d){
    if(!this.uuidRegister.has(id)) return null;

    this.scheduledPacketsAlways.add({'id':id,'port':port,'data': d});
    if(this.isDead || this.isFrozen) return null;
    
    this.filterNode(id).then((r){
        if(!r.data.hasPort(port)) return null;
        r.data.port(port).send(d);
    });
  }

  void schedulePacket(String id,String port,dynamic d,[Completer mixer]){
    if(!this.uuidRegister.has(id)) return null;

    this.scheduledPackets.add({'id':id,'port':port,'data': d,'mixer':mixer});

    if(this.isDead || this.isFrozen) return null;
    
    return this._runScheduledPackets();
  }

  void removeAlwaysScheduledPackets(String id,[String port]){
    if(!this.uuidRegister.has(id)) return null;

    this.scheduledPacketsAlways.remove(id,(it,n){
      if(port != null){
          if(it.current['id'] == id && it.current['port'] == port) return true;
          return false;
      };
      if(it.current['id'] == id) return true;
      return false;
    });
  }

  void removeScheduledPackets(String id,[String port]){
    if(!this.uuidRegister.has(id)) return null;

    this.scheduledPackets.remove(id,(it,n){
      if(port != null){
          if(it.current['id'] == id && it.current['port'] == port) return true;
          return false;
      };
      if(it.current['id'] == id) return true;
      return false;
    });
  }

  void _runBootUpScheduledPackets(){
    this.scheduledPacketsAlwaysIterator.cascade((it){
       var cur = it.current;
      this.filterNode(cur['id']).then((r){
          if(!r.data.hasPort(cur['port'])) return null;
          r.data.port(cur['port']).send(cur['data']);
      });
    });
  }

  void _runScheduledPackets(){
    while(hub.Valids.not(this.scheduledPackets.isEmpty)){
      var node = this.scheduledPackets.removeHead(), cur;
      if(hub.Valids.exist(node)){
        cur = node.data;
        var mixer = cur['mixer'];
        this.filterNode(cur['id']).then((r){
          if(!r.data.hasPort(cur['port'])) return null;
          if(hub.Valids.notExist(mixer)) 
            return r.data.port(cur['port']).send(cur['data']);
          return mixer.complete([r.data,r.data.port(cur['port']),cur['data']]);
        }).catchError((e){
          if(hub.Valids.exist(mixer)) mixer.completeError(e);
        });
        node.free();
      }
    }
  }

  Future useComponent(FlowComponent a,String id,[Function n]){
    var node = this.components.add(a);
    this.components.bind(this.placeholder,node,0);
    this.components.bind(node,this.placeholder,1);
    this.uuidRegister.add(id,a.uuid);
    this.componentStream.emit(SparkFlowMessages.component('addComponent',id,a.uuid));
    if(n != null) n(meta.component);
    return new Future.value(node);
  }

  Future use(String path,String id,[Function n,List a,Map m]){
    if(!Sparkflow.registry.has(path)) return new Future.error(new Exception('Component $path not found!'));
    return this.useComponent(Sparkflow.registry.generate(path,a,m),id,n);
  }

  Future destroy(String name,[Function n,bool bf]){
    if(!this.uuidRegister.has(name)) return null;
    return this.remove(name,n,bf).then((_){
      return _.data.kill();
    });
  }

  Future remove(String a,[Function n,bool bf]){
    if(!this.uuidRegister.has(a)) return null;

    var comso = this.filterNode(a,bf);
    return comso.then((_){
      if(n != null) n(_.data);
      _.data.detach();
      this.components.eject(_);
      this.componentStream.emit(SparkFlowMessages.component('removeComponent',a,_.data.uuid));
    }).catchError((e){
      this.componentStream.emit({'type':'network-remove', 'error': e, 'component': a });
    });
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

      this._runScheduledPackets();
      this._runBootUpScheduledPackets();
      this.stateManager.switchState('alive');
      this.networkStream.emit({ 'type':"bootingNetwork", 'status':true,'message': 'booting network operations'});
      this.onAlive.emit(this);
      this.startStamp = new DateTime.now();

      return completer.future;
    },(e){ throw e; });

    return this.whenAlive;
  }
  
  Future unfreeze(){
    this.unlockNetworkStreams();
    return this.boot();
  }

  Future _internalPort(String port,Function n,[dynamic d,bool bf]){
      var c = new Completer();
      if(this.hasPort(port)) c.completeError(new Exception("${this.UID} has no port called $port"));
      else{
        var pt = this.port(port);
        c.complete(pt);
        n(pt);
      }
      return c.future;
  }

  Future endStream(String id,String port,[dynamic d,bool bf]){
    if(hub.Valids.match(id,"*")) 
      return this._internalPort(port,(pt){
        if(d != null) pt.send(d);
        pt.endStream();
      });

    return this.filterNode(id,bf).then((_){
        var pt = _.data.port(port);
        hub.Funcs.when(hub.Valids.exist(pt),(){
            if(d != null) pt.send(d);
            pt.endStream();
        });
    }).catchError((e) => throw e);
  }

  Future send(String id,String port,dynamic d,[bool bf]){
    if(hub.Valids.match(id,"*")) 
      return this._internalPort(port,(pt) => pt.send(d));
     var mix = new Completer();
     this.schedulePacket(id,port,d,mix);
     return mix.future.then((_){
        var own = _[0], prt = _[1], data = _[2];
        if(hub.Valids.exist(prt)) prt.send(data);
        else throw "$id has no port called $port";
        return own;
     });
  }

  Future beginGroup(String id,String port,dynamic d,[bool bf]){
    if(hub.Valids.match(id,"*")) 
      return this._internalPort(port,(pt) => pt.beginGroup(d));
     var mix = new Completer();
     this.schedulePacket(id,port,d,mix);
     return mix.future.then((_){
        var own = _[0], prt = _[1], data = _[2];
        if(hub.Valids.exist(prt)) prt.beginGroup(data);
        else throw "$id has no port called $port";
        return own;
     });
  }

  Future endGroup(String id,String port,dynamic d,[bool bf]){
    if(hub.Valids.match(id,"*")) 
      return this._internalPort(port,(pt) => pt.endGroup(d));
     var mix = new Completer();
     this.schedulePacket(id,port,d,mix);
     return mix.future.then((_){
        var own = _[0], prt = _[1], data = _[2];
        if(hub.Valids.exist(prt)) prt.endGroup(data);
        else throw "$id has no port called $port";
        return own;
     });
  }

  Future tapEnd(String id,String port,Function d,[bool bf]){
    if(hub.Valids.match(id,"*")) 
      return this._internalPort(port,(pt) => pt.tapEnd(d));
    return this.filterNode(id,bf).then((_){
        var pt = _.data.port(port);
        hub.Funcs.when(hub.Valids.exist(pt),(){
            pt.tapEnd(d);
        });
    }).catchError((e) => throw e);
  }

  Future untapEnd(String id,String port,Function d,[bool bf]){
    if(hub.Valids.match(id,"*")) 
      return this._internalPort(port,(pt) => pt.untapEnd(d));
    return this.filterNode(id,bf).then((_){
        var pt = _.data.port(port);
        hub.Funcs.when(hub.Valids.exist(pt),(){
            pt.untapEnd(d);
        });
    }).catchError((e) => throw e);
  }

  Future tapData(String id,String port,Function d,[bool bf]){
    if(hub.Valids.match(id,"*")) 
      return this._internalPort(port,(pt) => pt.tapData(d));
    return this.filterNode(id,bf).then((_){
        var pt = _.data.port(port);
        hub.Funcs.when(hub.Valids.exist(pt),(){
            pt.tapData(d);
        });
    }).catchError((e) => throw e);
  }

  Future tapEndGroup(String id,String port,Function d,[bool bf]){
    if(hub.Valids.match(id,"*")) 
      return this._internalPort(port,(pt) => pt.tapEndGroup(d));
    return this.filterNode(id,bf).then((_){
        var pt = _.data.pt(port);
        hub.Funcs.when(hub.Valids.exist(pt),(){
            pt.tapBeginGroup(d);
        });
    }).catchError((e) => throw e);
  }

  Future tapBeginGroup(String id,String port,Function d,[bool bf]){
    if(hub.Valids.match(id,"*")) 
      return this._internalPort(port,(pt) => pt.tapBeginGroup(d));
    return this.filterNode(id,bf).then((_){
        var pt = _.data.port(port);
        hub.Funcs.when(hub.Valids.exist(pt),(){
            pt.tapBeginGroup(d);
        });
    }).catchError((e) => throw e);
  }

  Future tap(String id,String port,Function d,[bool bf]){
    if(hub.Valids.match(id,"*")) 
      return this._internalPort(port,(pt) => pt.tap(d));
    return this.filterNode(id,bf).then((_){
        var pt = _.data.port(port);
        hub.Funcs.when(hub.Valids.exist(pt),(){
            pt.tap(d);
        });
    }).catchError((e) => throw e);
  }

  Future tapOnce(String id,String port,Function d,[bool bf]){
    if(hub.Valids.match(id,"*")) 
      return this._internalPort(port,(pt) => pt.tapOnce(d));
    return this.filterNode(id,bf).then((_){
        var pt = _.data.port(port);
        hub.Funcs.when(hub.Valids.exist(pt),(){
            pt.tapOnce(d);
        });
    }).catchError((e) => throw e);
  }

  Future untapOnce(String id,String port,Function d,[bool bf]){
    if(hub.Valids.match(id,"*")) 
      return this._internalPort(port,(pt) => pt.untapOnce(d));
    return this.filterNode(id,bf).then((_){
        var pt = _.data.port(port);
        hub.Funcs.when(hub.Valids.exist(pt),(){
            pt.untapOnce(d);
        });
    }).catchError((e) => throw e);
  }

  Future untap(String id,String port,Function d,[bool bf]){
    if(hub.Valids.match(id,"*")) 
      return this._internalPort(port,(pt) => pt.untap(d));
    return this.filterNode(id,bf).then((_){
        var pt = _.data.port(port);
        hub.Funcs.when(hub.Valids.exist(pt),(){
            pt.untap(d);
        });
    }).catchError((e) => throw e);
  }


  Map get toMeta{
    var meta = {};
    meta['metas'] = new Map.from(this.metas.storage);
    meta['ports'] = this.networkPorts.toMeta;
    meta['id'] = this.id;

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
        m['connections'] = comp.connections;
        m.remove('portClass');
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

  void ensureSetBinding(String from,String fp,List tolist,String tp,[String sid,bool ve,bool f]){
    tolist.forEach((k){
      return this.ensureBinding(from,fp,k,tp,sid,ve,f);
    });
  }

  void ensureSetUnbinding(String from,String fp,List tolist,[String sid,bool f]){
    tolist.forEach((k){
      return this.ensureUnBinding(from,fp,k,tp,sid,f);
    });
  }

  void looseSetBinding(String from,String fp,List tolist,[String sid,bool ve,bool f]){
    tolist.forEach((k){
      return this.looseBinding(from,fp,k,tp,sid,ve,f);
    });
  }

  void looseSetUnbinding(String from,String fp,List tolist,[String sid,bool f]){
    tolist.forEach((k){
      return this.looseUnBinding(from,fp,k,tp,sid,f);
    });
  }

  void ensureAllBinding(String from,String fp,Map tolist,[String sid,bool ve,bool f]){
    tolist.forEach((k,v){
       return this.ensureBinding(from,fp,k,v,sid,ve,f);
    });
  }

  void ensureAllUnbinding(String from,String fp,Map tolist,[String sid,bool f]){
    tolist.forEach((k,v){
       return this.ensureUnBinding(from,fp,k,v,sid,f);
    });
  }

  void looseAllBinding(String from,String fp,Map tolist,[String sid,bool ve,bool f]){
    tolist.forEach((k,v){
       return this.looseBinding(from,fp,k,v,sid,ve,f);
    });
  }

  void looseAllUnbinding(String from,String fp,Map tolist,[String sid,bool f]){
    tolist.forEach((k,v){
       return this.looseUnbinding(from,fp,k,v,sid,f);
    });
  }

  void ensureBinding(String from,String fp,String to,String tp,[String sid,bool ve,bool f]){
    this.onAliveConnect((net){
       return this.doBinding(from,fp,to,tp,sid,ve,f);
    });
  }

  void ensureUnbinding(String from,String fp,String to,String tp,[String sid,bool f]){
    this.onDeadDisconnect((net){
       return this.doUnBinding(from,fp,to,tp,sid,f);
    });
  }

  void looseBinding(String from,String fp,String to,String tp,[String sid,bool ve,bool f]){
     return this.doBinding(from,fp,to,tp,sid,ve,f);
  }

  void looseUnbinding(String from,String fp,String to,String tp,[String sid,bool f]){
     return this.doUnBinding(from,fp,to,tp,sid,f);
  }

  Network link(String nport,String com,String inport,[String sid,bool ve,bool bf,bool inverse]){
    if(!this.networkPorts.hasPort(nport)) return null;
    inverse = hub.Hub.switchUnless(inverse,false);
    this.connectionsCompiler.add((){
      return this.filterNode(com,bf).then((_){
        if(!_.data.hasPort(inport)) return null;

        if(!!inverse){
         this.connectionStream.emit(SparkFlowMessages.network('link','*',com,inport,nport,sid));        
          _.data.port(inport).bindPort(this.port(nport),sid,ve); 
          return _;
        }
        
        this.port(nport).bindPort(_.data.port(inport),sid,ve);    
        this.connectionStream.emit(SparkFlowMessages.network('link',com,'*',nport,inport,sid));
        return _;
      });
    });

    return this;
  }

  Network unlink(String nport, String com,String comport,[String sid,bool bf,bool inverse]){
    if(!this.networkPorts.hasPort(nport)) return null;
    inverse = hub.Hub.switchUnless(inverse,false);
    this.disconnectionsCompiler.add((){
        return this.filterNode(com,bf).then((_){
        if(!_.data.hasPort(comport)) return null;

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
  
  void doBinding(String from,String fp,String to,String tp,[String sid,bool ve,bool f]){
      
      hub.Funcs.when((from == to && to != "*"),(){

          this.filterNode(from).then((n){
            n.data.loopPorts(tp,fp,sid,ve);
            this.connectionStream.emit(SparkFlowMessages.network('loop',from,to,fp,tp,sid));
          }).catchError((e){
            this.connectionStream.emit(SparkFlowMessages.network('loop',from,to,fp,tp,sid,e));
          });

      });

      hub.Funcs.when((from == "*" && to == "*"),(){
          return this.loopPorts(fp,tp,sid,ve);
      });

      hub.Funcs.when((from != "*" && to != "*"),(){
          return this.connect(from,fp,to,tp,sid,ve,f);
      });

      hub.Funcs.when((from == "*" && to != '*'),(){
        return this.link(fp,to,tp,sid,ve,f,false);
      });

      hub.Funcs.when((from != "*" && to == '*'),(){
        return this.link(tp,from,fp,sid,ve,f,true); 
      });

  }

  void doUnBinding(String from,String fp,String to,String tp,[String sid,bool f]){

      hub.Funcs.when((from == to && to != "*"),(){

          this.filterNode(from).then((n){
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
        return this.unlink(fp,to,tp,sid,f,false);
      });

      hub.Funcs.when((from != "*" && to == '*'),(){
        return this.unlink(tp,from,fp,sid,f,true);
      });

  }

  Network connect(String a,String aport,String b, String bport,[String sockid,bool ve,bool bf]){
    if(!this.uuidRegister.has(a)) return null;
    if(!this.uuidRegister.has(b)) return null;

    var waiter = (){
      var comso = this.filterNode(a,bf);
      var comsa = this.filterNode(b,bf);
      return Future.wait([comso,comsa]).then((_){
          var from = _[0], to = _[1];
          from.data.bind(aport,to.data,bport,sockid,ve);
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
      var comso = this.filterNode(a,bf);
      var comsa = this.filterNode(b,bf);
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

  Network loopPorts(String p,String s,[String sid,bool ve]){
    var wait = (){
      var p1 = this.port(p);
      var p2 = this.port(s);

      if(hub.Valids.exist(p1) && hub.Valids.exist(p2)){
        p1.bindPort(p2,sid,ve);
        this.connectionStream.emit(SparkFlowMessages.network('loop','*','*',p,s,sid));
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
        this.connectionStream.emit(SparkFlowMessages.network('unloop','*','*',p,s,sid));
      }
      return new Future.value([p1,p2]);
    };

    this.disconnectionsCompiler.add(wait);
    return this;
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

class PortGroup{
  final defaults = {
    'schema':'dynamic',
    'datatype':'dynamic',
    'engine':'sparkflow',
  };
  final Streamable events = Streamable.create();
  final portLists = new hub.MapDecorator();
  FlowComponent owner;
  String groupClass;
  
  static create(g,[m]) => new PortGroup(g,m);

  PortGroup(this.groupClass,[this.owner]);

  dynamic _packets(d,w,r,e){
    var ip = Packet.create();
    ip.init(d,w,r.UID,e);
    return ip;
  }
  
  Map get toMeta{
    var m = {};
    /* var m = {'inports':{},'outports':{}}; */
    this.portLists.onAll((e,k){
      /* var type = k.portType.isInport ? 'inports' : 'outports'; */
      m[e] = {
        'id': e,
        'meta': new Map.from(k.meta.storage),
        'component': (hub.Valids.exist(k.owner) ? k.owner.UID : null),
        'tag': k.tag,
        'group': k.meta.get('group'),
        'class': k.portClass
      };
    });

    return m;
  }
  
  dynamic getPort(String name){
    return this.portLists.get(name);
  }
  
  dynamic addInport(String name,Map m){
    return this._addPort(name,m,(a,b,c){
        return Inport.create(a,b,c);
    });
  }

  dynamic addOutPort(String name,Map m){
    return this._addPort(name,m,(a,b,c){
        return Outport.create(a,b,c);
    });
  }

  void addInportObject(String name,Inport m){
    this._addPortObject(name,m);
  }

  void addOutPortObject(String name,Outport m){
    this._addPortObject(name,m);
  }

  void _addPort(String name,Map meta,Function g){
    if(meta == null) meta = {};
    if(this.portLists.has(name)) return null;
    var port = g(name,hub.Enums.merge(meta,this.defaults),this.owner);
    port.meta.update('group',this.groupClass);
    var metad = new Map.from(port.meta.storage);
    this.portLists.add(name,port);
    this.events.emit(this._packets('addPort',metad,port.owner,port.id));
  }
  
  void _addPortObject(String name,Port p){
    if(this.portLists.has(name)) return null;
    p.meta.update('group',this.groupClass);
    var metad = new Map.from(p.meta.storage);
    this.portLists.add(name,p);
    this.events.emit(this._packets('addPort',metad,p.owner,p.id));
  }

  dynamic removePort(String name){
    if(!this.portLists.has(name)) return null;
    var port = this.portLists.destroy(name);
    var meta = new Map.from(port.meta);
    this.events.emit(this._packets('removePort',meta,port.owner,port.id));
    port.clearHooks();
    return port;
  }
  
  bool has(String name){
    return this.portLists.has(name);
  }
  
  void close(){
    this.flushAll();
    this.portLists.onAll((n,k){
      k.close();
    });
  }
  
  void destroyAll(){
    this.portLists.flush();
  }

  void pausePort(String name){
    if(!this.portLists.has(name)) return null;
    var port = this.portLists.get(name);
    this.events.emit(this._packets('pausePort',new Map.from(port.meta.storage),port.owner,port.id));
    return port.pause();
  }

  void resumePort(String name){
    if(!this.portLists.has(name)) return null;
    var port = this.portLists.get(name);
    this.events.emit(this._packets('resumePort',new Map.from(port.meta.storage),port.owner,port.id));
    return port.resume();
  }

  void flushPort(String name){
    if(!this.portLists.has(name)) return null;
    var port = this.portLists.get(name);
    this.events.emit(this._packets('flushPort',new Map.from(port.meta.storage),port.owner,port.id));
    return port.flushPackets();
  }

  void resumeAll(){
    this.portLists.onAll((n,k){
      this.resumePort(n);
    });
  }

  void pauseAll(){
    this.portLists.onAll((n,k){
      this.pausePort(n);
    });
  }

  void flushAll(){
    this.portLists.onAll((n,k){
      this.flushPort(n);
    });
  }

  String toString(){
    return this.portLists.toString();
  }
}

class PortManager{
    final portsGroup = hub.MapDecorator.create();
    dynamic owner;

    static create(n) => new PortManager(n);

    PortManager(this.owner);
    
    Map get toMeta{
      var data = {};
      this.portsGroup.onAll((n,k){
        data[n] = k.toMeta;
      });
      return data;
    }
    
    bool hasSpace(String id){
        return this.portsGroup.has(id);
    }

    dynamic getSpace(String id){
      return this.portsGroup.get(id);
    }

    void createSpace(String id){
        if(this.hasSpace(id)) return null;
        this.portsGroup.add(id,PortGroup.create(id,this.owner));
    }

    void destroySpace(String id){
      this.portsGroup.destroy(id).close();
    }
    
    void destroySpacePorts(String id){
      this.portsGroup.get(id).close();
    }

    void destroyAllSpaces([Function n]){
      this.portsGroup.onAll((e,k){
        if(n != null && !!n(e,k)) return k.close();
        return k.close();
      });
    }

    FlowPort createInport(String id,{Map meta,Inport port}){
      var path = splitPortMap(id),
          finder = hub.Enums.nthFor(path);

      if(hub.Valids.notExist(path)) throw "This '$id' is wrong,port names must be in name_of_space:port_name format";
      if(hub.Valids.notExist(path) || !this.hasSpace(finder(0))) this.createSpace(finder(0));

      if(hub.Valids.exist(port)) this.portsGroup.get(finder(0)).addInportObject(finder(1),port);
      else this.portsGroup.get(finder(0)).addInport(finder(1),meta);

      return this.port(id);
    }

    FlowPort createOutport(String id,{Map meta,Outport port}){
      var path = splitPortMap(id),
          finder = hub.Enums.nthFor(path);

      if(hub.Valids.notExist(path)) throw "This '$id' is wrong,port names must be in name_of_space:port_name format";
      if(hub.Valids.notExist(path) || !this.hasSpace(finder(0))) this.createSpace(finder(0));

      if(hub.Valids.exist(port)) this.portsGroup.get(finder(0)).addOutPortObject(finder(1),port);
      else this.portsGroup.get(finder(0)).addOutPort(finder(1),meta);

      return this.port(id);
    }

    FlowPort destroyPort(String id){
      if(!this.hasPort(id)) return null;

      var path = splitPortMap(id),
          finder = hub.Enums.nthFor(path);

      var port = this.getSpace(finder(0)).removePort(finder(1));
      if(hub.Valids.exist(port)) port.close();
      return port;
    }

    FlowPort port(String id){
      var path = splitPortMap(id),
          finder = hub.Enums.nthFor(path);

      if(hub.Valids.notExist(path) || !this.portsGroup.has(finder(0))) 
        return null;

      return this.portsGroup.get(finder(0)).getPort(finder(1));
    }
  
    bool hasPort(String id){
      var path = splitPortMap(id),
          finder = hub.Enums.nthFor(path);

      if(hub.Valids.notExist(path) || !this.portsGroup.has(finder(0))) 
        return false;

      return this.portsGroup.get(finder(0)).has(finder(1));
    
    }

    void opsOnPort(String n,Function m){
      var path = n.split(':'),
          finder = hub.Enums.nthFor(path);

      if(path.isEmpty || !this.portsGroup.has(finder(0))) 
        return false;

      return m(this.portsGroup.get(finder(0)),finder(1));
    }
    
    void close(){
      this.destroyAllSpaces();
    }

    void destroyAll(){
      this.portsGroup.onAll((e,k){
        return k.destroyAll();
      });
      this.portsGroup.flush();
    }

    void flushAllPackets(){
      this.portsGroup.onAll((e,k){
         k.flushAll();
      });
    }

    void resumeAll(){
      this.portsGroup.onAll((e,k){
          k.resumeAll();
      });
    }

    void pauseAll(){
      this.portsGroup.onAll((e,k){
          k.pauseAll();
      });
    }

    void flushPort(String n){
      this.opsOnPort(n,(g,nm){

        hub.Funcs.when(hub.Valids.exist(nm),(){
            g.flushPort(nm);
        },(){
           g.flushAll();
        });

      });
    }

    void resumePort(String n){
      this.opsOnPort(n,(g,nm){

        hub.Funcs.when(hub.Valids.exist(nm),(){
            g.resumePort(nm);
        },(){
           g.resumeAll();
        });

      });
    }

    void pausePort(String n){
      this.opsOnPort(n,(g,nm){

        hub.Funcs.when(hub.Valids.exist(nm),(){
            g.pausePort(nm);
        },(){
           g.pauseAll();
        });

      });
    }

    String toString(){
       return this.portsGroup.toString();
    }
}

/*class for component*/
class Component extends FlowComponent{
  final connectionStream = Streamable.create();
  final stateStream = Streamable.create();
  final bootups = Distributor.create('connection_bootup');
  final freezups = Distributor.create('connection_freeze');
  final shutdowns = Distributor.create('connection_shutdowns');
  hub.StateManager sharedState;
  var _connections,network;
  PortManager comPorts;

  static create([String id]) => new Component(id);
  static createFrom(Map m) => new Component.From(m);

  Map get toMeta{
    var payload = {};

    payload['metas'] = new Map.from(this.metas.storage);

    payload['metas'].remove('ports');
    payload['metas'].remove('uuid');
    payload['metas'].remove('id');
    payload['metas'].remove('group');
    
    payload['uuid'] = this.metas.get('uuid');
    payload['ports']= this.comPorts.toMeta;
    payload['id'] = this.id;
    payload['uid'] = this.UID;
    payload['group'] = this.metas.get('group');
    
    return payload;
  }

  Component([String id]): super((id == null ? 'Component' : id)){
    this.comPorts = PortManager.create(this);
    this._connections = ConnectionMeta.create(this);
    this.sharedState = hub.StateManager.create(this);

    this.sharedState.add('booted',{
      'frozen': (t,c){ return false; },
      'dead': (t,c){ return false; },
      'alive': (t,c){ return true; },
    });

    this.sharedState.add('frozen',{
      'frozen': (t,c){ return true; },
      'dead': (t,c){ return false; },
      'alive': (t,c){ return false; },
    });

    this.sharedState.add('shutdown',{
      'frozen': (t,c){ return false; },
      'dead': (t,c){ return true; },
      'alive': (t,c){ return false; },
    });


    this.connectionStream.on((e){
      
      hub.Funcs.when(hub.Valids.match(e['type'],'bind'),(){
        this._connections.addConnection(e['fromPort'],e['to'],e['toPort'],e['socketid']);
      });

      hub.Funcs.when(hub.Valids.match(e['type'],'unbind'),(){
        this._connections.removeConnection(e['fromPort'],e['to'],e['toPort'],e['socketid']);
      });

    });

    this.sharedState.switchState('shutdown');
  }
  

  bool get isAlive{
    return this.sharedState.run('alive');
  }

  bool get isFrozen{
    return this.sharedState.run('frozen');
  }

  bool get isDead{
    return this.sharedState.run('dead');
  }

  bool hasPort(String g){
    return this.comPorts.hasPort(g);
  }

  void createSpace(String g){
    this.comPorts.createSpace(g);
  }

  void destroySpace(String g){
    this.comPorts.destroySpace(g);
  }

  void destroyPort(String g){
    this.comPorts.destroyPort(g);
  }

  FlowPort makeInport(String id,{ Map meta: null,Inport port:null }){
    return this.comPorts.createInport(id,meta:meta,port:port);
  }

  FlowPort makeOutport(String id,{ Map meta: null,Outport port:null }){
    return this.comPorts.createOutport(id,meta:meta,port:port);
  }

  FlowPort createProxyInport(String id,{Map meta, Inport port:null}){
    this.enableSubnet();
    var pt = this.makeInport(id,meta:meta,port:port);
    this.network.makeInport(id,meta:meta,port: pt);
  }

  FlowPort createProxyOutport(String id,{Map meta, Inport port:null}){
    this.enableSubnet();
    var pt = this.makeOutport(id,meta:meta,port:port);
    this.network.makeOutport(id,meta:meta,port: pt);
  }

  void createDefaultPorts(){
    this.createSpace('in');
    this.createSpace('out');
    this.createSpace('err');

    this.makeInport('in:in');
    this.makeOutport('out:out');
    this.makeOutport('err:err');
  }

  FlowPort port(String n){
    return this.comPorts.port(n);
  }
  
  void useSubnet(Network n){
    if(this.network != null) return null;
    this.network = n;
  }

  void enableSubnet(){
    if(hub.Valids.exist(this.network)) return null;
    this.network = Network.create(this.id+':Subnet');
  }

  void disableSubnet(){
    if(this.network == null) return;
    this.network.close();
    this.network = null;
  }

  Map get connections{
    return new Map.from(this._connections.storage);
  }

  void ensureOnBoot(Function n){
    this.bootups.on(n);
  }

  void ensureOnFreeze(Function n){
    this.freezups.on(n);
  }

  void ensureOnShutdown(Function n){
    this.shutdowns.on(n);
  }

  Future boot(){
    if(this.isAlive) return new Future.value(this);
    if(this.isDead) this.bootups.emit(this);
    /*this.comPorts.pauseAll();*/
    this.stateStream.emit({'type':'boot','id': this.id,'uuid':this.metas.get('uuid')});
    this.sharedState.switchState('booted');
    if(this.network != null) return this.network.boot().then((n){ 
      /*this.comPorts.resumeAll();*/
      return this; 
    });
    /*this.comPorts.resumeAll();*/
    return new Future.value(this);
  }

  Future unfreeze(){
    this.comPorts.resumeAll();
    return this.boot();
  }

  Future freeze(){
    if(this.isFrozen) return new Future.value(this);
    this.freezups.emit(this);
    this.comPorts.pauseAll();
    this.stateStream.emit({'type':'freeze','id': this.id,'uuid':this.metas.get('uuid')});
    this.sharedState.switchState('frozen');
    if(this.network != null) return this.network.freeze().then((n){ return this; });
    return new Future.value(this);
  }

  Future shutdown(){
    if(this.isDead) return new Future.value(this);
    this.shutdowns.emit(this);
    this.comPorts.flushAllPackets();
    this.comPorts.pauseAll();
    this.stateStream.emit({'type':'shutdown','id': this.id,'uuid':this.metas.get('uuid')});
    this.sharedState.switchState('shutdown');
    if(this.network != null) return this.network.shutdown().then((n){ return this; });
    return new Future.value(this);
  }

  Future kill(){
    this.comPorts.close();
    return this.shutdown();
  }

  dynamic bind(String myport,Component component,String toport,[String socketId,bool ve]){
    if(!this.hasPort(myport) || !component.hasPort(toport)) return null;

    var myPort = this.port(myport),
          toPort = component.port(toport);

    this.connectionStream.emit(SparkFlowMessages.componentConnection('bind',component.UID,this.UID,toport,myport,socketId));
    return myPort.bindPort(toPort,socketId,ve);
  }

  dynamic unbind(String myport,Component component,String toport,[String mysocketId]){
    if(!this.hasPort(myport) || !component.hasPort(toport)) return null;

    var myPort = this.port(myport),
          toPort = component.port(toport);
    
    this.connectionStream.emit(SparkFlowMessages.componentConnection('unbind',component.UID,this.UID,toport,myport,mysocketId));
    return myPort.unbindPort(toPort);
  }
  
  void unloopPorts(String v,String u){
    var from = this.port(v);
    var to = this.port(u);

    if(to != null && from != null){
      from.unbindPort(to);
    this.connectionStream.emit(SparkFlowMessages.componentConnection('loop',this.UID,this.UID,u,v,null));
    }
  }

  void loopPorts(String v,String u,[String sid,bool ve]){
    var from = this.port(v);
    var to = this.port(u);

    if(to != null && from != null){
      from.bindPort(to,sid,ve);
    this.connectionStream.emit(SparkFlowMessages.componentConnection('loop',this.UID,this.UID,u,v,null));
    }
  }

  void close(){
    this.disableSubnet();
    this.ports.onAll((n) => n.detach());
  }

  void _checkPort(String id){
    if(this.hasPort(id)) return null;
    return new Exception('$id port is not exisiting!');
  }

  void send(String port,dynamic d){
    this._checkPort(port);
    return this.port(port).send(d);
  }

  void endStream(String port,[dynamic d]){
    this._checkPort(port);
    var pt = this.port(port);
    if(d != null) pt.send(d);
    return pt.endStream();
  }

  void beginGroup(String port,dynamic d,[bool bf]){
    this._checkPort(port);
    return this.port(port).beginGroup(d);
  }

  void endGroup(String port,dynamic d,[bool bf]){
    this._checkPort(port);
    return this.port(port).endGroup(d);
  }

  void tapEnd(String port,Function d,[bool bf]){
    this._checkPort(port);
    return this.port(port).tapEnd(d);
  }

  void untapEnd(String port,Function d,[bool bf]){
    this._checkPort(port);
    return this.port(port).untapEnd(d);
  }

  void tapData(String port,Function d,[bool bf]){
    this._checkPort(port);
    return this.port(port).tapData(d);
  }

  void tapEndGroup(String port,Function d,[bool bf]){
    this._checkPort(port);
    return this.port(port).tapEndGroup(d);
  }

  void tapBeginGroup(String port,Function d,[bool bf]){
    this._checkPort(port);
    return this.port(port).tapBeginGroup(d);
  }

  void tap(String port,Function d,[bool bf]){
    this._checkPort(port);
    return this.port(port).tap(d);
  }

  void tapOnce(String port,Function d,[bool bf]){
    this._checkPort(port);
    return this.port(port).tapOnce(d);
  }

  void untapOnce(String port,Function d,[bool bf]){
    this._checkPort(port);
    return this.port(port).untapOnce(d);
  }

  void untap(String port,Function d,[bool bf]){
    this._checkPort(port);
    return this.port(port).untap(d);
  }


}

class MassTree extends hub.MapDecorator{
  final canDestroy = hub.Switch.create();

  static create() => new MassTree();

  MassTree();

  dynamic destroy(String key){
    if(!this.canDestroy.on()) return null;
    return super.destroy(key);
  }

  void addAll(Map n){
    n.forEach((n,k){
      this.add(n,k);
    });
  }
}


class ComponentGroup{
  final groups = new hub.MapDecorator();
  final String uuid = hub.Hub.randomString(7);
  String id;

  static create(id) => new ComponentGroup(id);

  ComponentGroup(this.id);

  void add(String handle,Function generator){
      handle = handle.toLowerCase();
    if(this.groups.has(handle)) return null;

    var path = this.id+"/"+handle;
    this.groups.add(handle,([List ops,Map named]){
      ops = hub.Funcs.switchUnless(ops,[]);
      named = hub.Funcs.switchUnless(named,{});
      var com = Function.apply(generator,ops,hub.Hub.encryptNamedArguments(named));
      if(com is! FlowComponent) throw new Exception('$com is not a type of ${FlowComponent}');

      com.setGroup(path);
      return com;
    });
  }

  Function get(String handle){
      handle = handle.toLowerCase();
    return this.groups.get(handle);
  }

  bool has(String handle){
      handle = handle.toLowerCase();
    return this.groups.has(handle);
  }

  void eject(String handle){
      handle = handle.toLowerCase();
    if(!this.groups.has(handle)) return;
    this.groups.destroy(handle);
  }
  
  String toString(){
      return this.groups.toString();
  }

  List get toNames{
    return this.groups.storage.keys.toList();
  }
}


//SparkGroups provides a means of 
class SparkGroups{
  final groupSets = MassTree.create();

  static create() => new SparkGroups();

  SparkGroups();

  void enableRemove(){
    this.groupSets.canDestroy.switchOn();
  }

  void disableRemove(){
    this.groupSets.canDestroy.switchOff();
  }

  /*
    {
      transformers: ['StringPrefixer']
    }
  */
  Map get toGroupMeta{
    var mapped = {};
    this.groupSets.storage.forEach((n,k){
      mapped[n] = k.toNames;
    });

    return mapped;
  }

  /*
    ['transformers/StringPrefixer']   
  */
  List get toAddressMeta{
    var mapped = [];
    this.groupSets.storage.forEach((n,k){
      k.toNames.forEach((j){
        mapped.add(n+"/"+j);
      });
    });

    return mapped;
  }

  // transformers
  void addGroup(String handle){
    handle = handle.toLowerCase();
    if(this.groupSets.has(handle)) return null;
    this.groupSets.add(handle,ComponentGroup.create(handle));
  }
  
  ComponentGroup getGroup(String handle){
    handle = handle.toLowerCase();
    if(this.hasGroup(handle)) return this.groupSets.get(handle);
    return null;
  }

  bool hasGroup(String handle){
    handle = handle.toLowerCase();
    return this.groupSets.has(handle);
  }

  //transformers, StringPrefixer,[id,name],{id:name}
  dynamic generate(String handle,String type,[List ops,Map a]){
     handle = handle.toLowerCase();
     type = type.toLowerCase();
    var group = this.getGroup(handle);
    if(group == null || !group.has(type)) return null;
    return group.get(type)(ops,a);
  }


  //remove transformers;
  ComponentGroup removeGroup(String handle){
      handle = handle.toLowerCase();
    if(!this.groupSets.has(handle)) return null;
    var gp = this.groupSets.get(handle);
    this.groupSets.destroy(handle);
    return gp;
  }

  // true : false => transformers/StringPrefixer
  bool hasGroupString(String path){
      path = path.toLowerCase();
    var from = path.split('/');
    if(from.length < 2) return null;
    var group = hub.Enums.first(from);
    var name = hub.Enums.second(from);  
    return (this.hasGroup(group) ? this.getGroup(group).has(name) : false);
  }

  // components/component
  void addUsingString(String path,Function n){
      path = path.toLowerCase();
    var from = path.split('/');
    if(from.length < 2) return null;
    var group = hub.Enums.first(from);
    var name = hub.Enums.second(from);
    this.addGroup(group);
    this.getGroup(group).add(name,n);
  }

  //transformers/StringPrefixer
  dynamic getGroupFromString(String path){
      path = path.toLowerCase();
    var from = path.split('/');
    if(from.length < 2) return null;
    if(this.hasGroup(from.first)){
      var grp = this.getGroup(hub.Enums.first(from));
      return grp.get(hub.Enums.second(from));
    }
    return null;
  }

  //transformers/StringPrefixer,[id,name],{id:name}
  dynamic generateFromString(String path,[List ops,Map a]){
      path = path.toLowerCase();
    var item = this.getGroupFromString(path);
    if(item != null) return item(ops,a);
    return null;
  }
  
  String toString(){
    return this.groupSets.toString();
  }
}


 
class PacketList{
  ds.dsList<Packet> packets;
  dynamic iterator;
  String key;

  static create(n) => new PacketList(n);

  PacketList(this.key){
    this.packets = new ds.dsList<Packet>();
    this.iterator = this.packets.iterator;
  }

  void data(dynamic n,[own,pid]){
    this.packet(Packet.create().init('data',n,own,pid));
  }

  void packet(Packet p){
    this.packets.add(p);
  }

  void remove(Packet p){
    this.iterator.remove(p);
  }

  ds.dsList get lists => this.packets;
  dynamic get handle => this.iterator;
  bool get isPacketList => true;

  void forceClearAll(){
    this.iterator.cascade((n){ n.current.clearLists(); });
    this.packets.clear();
  }

  void clear(){
    this.packets.clear();
  }

  dynamic disjoin(){
    return packets.disjoin();
  }

  String toString(){
    var buffer = new StringBuffer();
    buffer.write('Tag: ${this.key}');
    buffer.write('\n');
    buffer.write('Lists: ${this.lists}');
    return buffer.toString();
  }

  void close(){
    this.lists.free();
    this.packets = this.iterator = null;
  }
}

class Packet extends hub.MapDecorator{

  static create() => new Packet();

  Packet(): super();
  

  Packet init(event,data,owner,portid){
    this.event = event;
    this.data = data;
    this.owner = owner;
    this.port = portid;
    this.add('_owner-root',owner);
    this.add('_lists',new hub.MapDecorator.use(new Map<String,PacketList>()));
    return this;
  }

  dynamic get event => this.get('event');
  dynamic get data => this.get('data');
  dynamic get owner => this.get('owner');
  dynamic get port => this.get('port');
  dynamic get lists => this.get('_lists');

  dynamic branch(String tag){
    if(!this.get('_lists').has(tag)) return null;
    return this.get('_lists').get(tag);
  }

  void addBranch(String tag,[PacketList g]){
    var ls = this.get('_lists');
    if(ls.has(tag)) return null;
    ls.add(tag,hub.Funcs.switchUnless(g,new PacketList<Packet>(tag)));
  }

  PacketList replaceBranch(String tag,PacketList g){
    var ls = this.get('_lists');
    if(!ls.has(tag)) return null;
    var old = ls.get(tag);
    ls.update(tag,g);
    return old;
  }

  dynamic set lists(Map<String,ds.dsList<Packet>> m){
    var m = this.get('_lists');
    this.update('_lists',new hub.MapDecorator.use(m));
    return m;
  }

  void clearLists(){
    this.lists.onAll((n,k) => k.forceClearAll());
    this.lists.flush();
  }

  void set port(String d){
    this.update('port',d);
  }

  void set event(String d){
    this.update('event',d);
  }

  void set data(dynamic d){
    if(this.has('data')) return this.update('data',d);
    this.add('data',d);
  }

  void set owner(String d){
    return this.update('owner',d);
  } 
  
  String toString(){
    var buffer = new StringBuffer();
    buffer.write('Packet:\n');
    buffer.write('\t event: ${this.event}\n');
    buffer.write('\t owner: ${this.owner}\n');
    buffer.write('\t data: ${this.data}\n');
    buffer.write('\t port: ${this.port}\n');
    buffer.write('\t packetList: ${this.lists}\n');
    return buffer.toString();
  }

  Packet lightClone(){
    var p = new Packet();
    p.init(this.event,this.data,this.owner,this.port);
    return p;
  }

  Packet deepClone(){
    var p = this.lightClone();
    p.lists = new Map.from(this.lists.storage);
    return p;
  }
}


class SparkRegistry{
  final SparkGroups groups = SparkGroups.create();

  static create() => new SparkRegistry();
  SparkRegistry();

   void addGroup(String handle){
    this.groups.addGroup(handle);
  }

   void addToGroup(String handle,String type,Function n){
    var g = this.groups.getGroup(handle);
    if(g != null) return g.add(type,n);
  }

   void register(String handle,String type,Function g){
    this.addGroup(handle);
    this.addToGroup(handle,type,g);
  }

   void unregister(String handle,String type){
    var handler = this.groups.getGroup(handle);
    if(handler == null) return null;
    return handler.eject(type);
  }

   dynamic createComponent(String handle,String type,[List l,Map a]){
    var c =  this.grabComponent(handle,type);
    if(c != null) return c(l,a);
  }

   dynamic grabComponent(String handle,String type){
    var g = this.groups.getGroup(handle);
    if(g != null) return g.get(type);
  }

  // true : false => transformers/StringPrefixer
   bool hasGroup(String path){
   return this.groups.hasGroupString(path);
  }

  // components/component
   void add(String path,Function n){
    return this.groups.addUsingString(path,n);
  }

  bool checkPath(String from){
    if(!this.hasGroup(from)) return null;
  }

  dynamic addBaseMutation(dynamic from,String path,Function mutation){
    var id = path.split('/');
    if(id.length <= 1) throw "path must be in group/id format";

    if(from is! String && from is! Function) return null;

    return this.add(path,([l,m]){
      var shell = from is Function ? from(l,m) : this.generate(from,l,m);
      shell.metas.add('mutationbase',[]);
      shell.metas.get('mutationbase').add(from is String ? from : shell.componentClassID);
      shell.setGroup(id[0]);
      shell.id = id[1];
      shell.mutate(mutation);
      return shell;
    });
  }

   dynamic addMutation(String path,Function mutation){
    var id = path.split('/');
    if(id.length <= 1) throw "path must be in group/id format";
    return this.add(path,([l,m]){
      var shell = Component.create(id[1]);
      shell.mutate(mutation);
      return shell;
    });
  }

  //transformers/StringPrefixer
   dynamic getGroup(String path){
    return this.groups.getGroupFromString(path);
  }

  //transformers/StringPrefixer,[id,name],{id:name}
   dynamic generate(String path,[List ops,Map a]){
    return this.groups.generateFromString(path,ops,a);
  }
  
  //geenrates a standard registered components but applies a function to it which may change the port configuration for that component before it gets returned for use,allows a form of dynamic changing of internal component operation
   dynamic generateMutation(String n,Function m,[List ops,Map a]){
    var shell = this.generate(n,ops,a);
    shell.mutate(m);
    return shell;
  }
}

class SparkRegistryManager{
  hub.MapDecorator registery_groups = hub.MapDecorator.create();

  static create() => new SparkRegistryManager();

  SparkRegistryManager(){
    this.registerNS('Core');
    this.register('Core','components','component',Component.create);
  }

  dynamic createRegistry(String nse,Function fn){
    if(this.hasNS(nse)) return fn(this.ns(nse));
    this.registerNS(nse);
    fn(this.ns(nse));
    return this;
  }

  void registerNS(String namespace){
    namespace = namespace.toLowerCase();
    this.registery_groups.add(namespace,SparkRegistry.create());
  }

  void unregisterNS(String namespace){
    namespace = namespace.toLowerCase();
    this.registery_groups.destroy(namespace);
  }

  bool hasNS(String nm){
    nm = nm.toLowerCase();
    return this.registery_groups.has(nm);
  }

  bool has(String nm){
    nm = nm.toLowerCase();
    var from = registryPathProcessor(nm);
    if(hub.Valids.notExist(from)) return false;
    var ne = hub.Enums.first(from);
    if(!this.hasNS(ne)) return false;
    return this.registry(ne).hasGroup((from[1]+"/"+from[2]));
  }

  dynamic registry(String nm){
    nm = nm.toLowerCase();
    if(!this.hasNS(nm)) return null;
    return this.registery_groups.get(nm);
  }

  dynamic ns(String nm) => this.registry(nm);

  dynamic register(String ns,String gp,String id,dynamic n){
    if(!this.hasNS(ns)) return null;
    var ne = this.registry(ns);
    return ne.register(gp,id,n);
  }

  dynamic generate(String path,[List ops,Map a]){
    path = path.toLowerCase();
    var from = registryPathProcessor(path);
    if(hub.Valids.notExist(from)) return null;
    var ne = hub.Enums.first(from);
    if(!this.hasNS(ne)) return null;
    var gp = hub.Enums.second(from);
    var id = hub.Enums.third(from);
    return this.registry(ne).generate((gp+"/"+id),ops,a);
  }

  dynamic addBaseMutation(String from,String to,Function mutation){
    if(!this.has(from)) return null;
    if(this.has(to)) return null;
    var t  = registryPathProcessor(to.toLowerCase());
    var ne = hub.Enums.first(t);
    if(!this.hasNS(ne)) return null;
    var gp = hub.Enums.second(t);
    var id = hub.Enums.third(t);
    return this.registry(ne).addBaseMutation((c,b){ return this.generate(from,c,b); },(gp+"/"+id),mutation);
    
  }

}

class Sparkflow{
  
  const Sparkflow();
  
  static SparkRegistryManager registry = SparkRegistryManager.create();

  static dynamic createRegistry(String ns,Function n){
    return Sparkflow.registry.createRegistry(ns,n);
  }

  static dynamic ns(String ns,[Function n]){
    var nd = Sparkflow.registry.ns(ns);
    if(n != null) n(nd);
    return nd;
  }

}

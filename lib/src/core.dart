library sparkflow;

import 'dart:async';
import 'package:hub/hub.dart' as hub;
import 'package:streamable/streamable.dart';
import 'package:ds/ds.dart' as ds;

part 'flow.dart';
part 'groups.dart';
part 'protocol.dart';
 
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
  final SparkGroups groups = hub.MapDecorator.create();

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
    this.groups.add(namespace,SparkRegistry.create());
  }

  void unregisterNS(String namespace){
    namespace = namespace.toLowerCase();
    this.groups.destroy(namespace);
  }

  bool hasNS(String nm){
    nm = nm.toLowerCase();
    return this.groups.has(nm);
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
    return this.groups.get(nm);
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

class Sparkflow extends FlowAbstract{
  final metas = new hub.MapDecorator.from({'desc':'top level flowobject'});
  Network network; 
  
  static SparkRegistryManager registry = SparkRegistryManager.create();

  static dynamic createRegistry(String ns,Function n){
    return Sparkflow.registry.createRegistry(ns,n);
  }

  static dynamic ns(String ns,[Function n]){
    var nd = Sparkflow.registry.ns(ns);
    if(n != null) n(nd);
    return nd;
  }

  static create(String id,[String desc]) => new Sparkflow(id,desc);

  Sparkflow(String id,[String desc]){
    this.metas.add('id',id);
    this.metas.add('desc',hub.Hub.switchUnless(desc,'basic sparkflow'));
    this.network = Network.create(id);
  }

  void onAliveConnect(Function n){
    this.network.onAliveConnect(n);
  }

  void onDeadDisconnect(Function n){
    this.network.onDeadDisconnect(n);
  }

  void onAlive(Function n){
    this.network.onAliveNetwork(n);
  }

  void onFrozen(Function n){
    this.network.onFrozenNetwork(n);
  }

  void onDead(Function n){
    this.network.onDeadNetwork(n);
  }

  void ensureSetBinding(String from,String fp,List to,String tp,[String sid,bool f]){
    return this.network.ensureSetBinding(from,fp,to,tp,sid,f);
  }

  void ensureSetUnbinding(String from,String fp,List to,String tp,[String sid,bool f]){
    return this.network.ensureSetUnbinding(from,fp,to,tp,sid,f);
  }

  void looseSetBinding(String from,String fp,List to,String tp,[String sid,bool f]){
    return this.network.looseSetBinding(from,fp,to,tp,sid,f);
  }

  void looseSetUnbinding(String from,String fp,List to,String tp,[String sid,bool f]){
    return this.network.looseSetUnbinding(from,fp,to,tp,sid,f);
  }

  void ensureAllBinding(String from,String fp,Map to,[String sid,bool f]){
    return this.network.ensureAllBinding(from,fp,to,sid,f);
  }

  void ensureAllUnbinding(String from,String fp,Map to,[String sid,bool f]){
    return this.network.ensureAllUnbinding(from,fp,to,sid,f);
  }

  void looseAllBinding(String from,String fp,Map to,[String sid,bool f]){
    return this.network.looseAllBinding(from,fp,to,sid,f);
  }

  void looseAllUnbinding(String from,String fp,Map to,[String sid,bool f]){
    return this.network.looseAllUnbinding(from,fp,to,sid,f);
  }

  void ensureBinding(String from,String fp,String to,String tp,[String sid,bool f]){
    return this.network.ensureBinding(from,fp,to,tp,sid,f);
  }

  void ensureUnbinding(String from,String fp,String to,String tp,[String sid,bool f]){
    return this.network.ensureUnbinding(from,fp,to,tp,sid,f);
  }

  void looseBinding(String from,String fp,String to,String tp,[String sid,bool f]){
    return this.network.looseBinding(from,fp,to,tp,sid,f);
  }

  void looseUnbinding(String from,String fp,String to,String tp,[String sid,bool f]){
    return this.network.looseUnbinding(from,fp,to,tp,sid,f);
  }

  dynamic use(String paths,String alias,[List a,Map m,Function n]){
    return this.network.add(paths,alias,n,a,m);
  }

  Future unUse(String alias,[Function n]){
    return this.network.remove(alias,n);
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

  void createDefaultPorts() => this.network.createDefaultPorts();

  dynamic port(n) => this.network.port(n);

  dynamic createSpace(n) => this.network.createSpace(n);

  dynamic makeOutport(n) => this.network.makeOutport(n);

  dynamic makeInport(n) => this.network.makeInport(n);

  dynamic removePort(n) => this.network.removePort(n);

  void close() => this.network.close();

  Future filter(n,[m]) => this.network.filter(n,m);

  dynamic addIIP(s,m) => this.network.addInitial(s,m);

  dynamic removeIIP(s,m) => this.network.addInitial(s,m);

  void sendInitials() => this.network.sendInitials();

  void schedulePacket(s,p,d) => this.network.schedulePacket(s,p,d);
  void alwaysSchedulePacket(s,p,d) => this.network.schedulePacket(s,p,d);
}


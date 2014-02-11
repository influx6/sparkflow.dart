library sparkflow;

import 'dart:async';
import 'package:hub/hub.dart' as hub;
import 'package:streamable/streamable.dart';
import 'package:ds/ds.dart' as ds;

part 'flow.dart';
part 'groups.dart';
part 'protocol.dart';


  /*
    Due to the current state of dynamic loading of coding ,beyond the use of defferedlibrary
    or using spawnURL and then transporting the loading objects from the spawned isolate (does not work in js),
    a simplified method was choosen where a library defines its components and provides a static method,where
    it registers them up into the SparkRegistry which is a global class with static objects and functions, and is used
    by the Sparkflow class to grab the components,so its a very important,do not miss it type of thing.

    I would prefer a simplified,automatically register the functions,but unlike JS we cant just run a function off in a 
    class file,so a alternate method was needed,if you wish to write your own components ensure to provide something similar
    to this to register up the components for global access by SparkFlow.
    Note: there is no way around it!

    Example: #from the /lib/components/unmodifiers.dart

    library sparkflow.unmodifiers;

    import 'package:hub/hub.dart';
    import 'package:sparkflow/sparkflow.dart';

    Feel free to defined yours as you prefer,either as this,or a static method in the Repeater class (a better option if its just one component),
    or as a global static function,just ensure to note it in the README.md or any viable documentation,with this when we load this library we simple
    call:
      UnModifiers.registerComponents();
    to add the sets of components to the global SparkRegistry and hence be able to address them in Sparkflow
       
    class UnModifiers{

      static void registerComponents(){
        SparkRegistry.register("unModifiers", 'Repeater', Repeater.create);
      }

    }

    class Repeater extends Component{

      static create() => new Repeater();

      Repeater(): super("Repeater"){
        this.meta('desc','a simple synchronous repeater component');
        this.loopPorts('in','out');
      }

    }
  
  
      this is a necessity and should be declared either as a static function in the class,to 
      add the necessary components to the SparkRegistery,unforunately there is no easy way
      to automatically run this once a library is imported;
  */ 
  
class SparkRegistry{
  static SparkGroups groups = SparkGroups.create();

  static void addGroup(String handle){
    SparkRegistry.groups.addGroup(handle);
  }

  static void addToGroup(String handle,String type,Function n){
    // if(!SparkRegistery.groups.hasGroup(handle)) SparkRegistery.addGroup(handle);
    var g = SparkRegistry.groups.getGroup(handle);
    if(g != null) return g.add(type,n);
  }

  static void register(String handle,String type,Function g){
    SparkRegistry.addGroup(handle);
    SparkRegistry.addToGroup(handle,type,g);
  }

  static void unregister(String handle,String type){
    var handler = SparkRegistry.groups.getGroup(handle);
    if(handler == null) return null;
    return handler.eject(type);
  }

  static dynamic createComponent(String handle,String type,[List l,Map a]){
    var c =  SparkRegistry.grabComponenet(handle,type);
    if(c != null) return c(l,a);
  }

  static dynamic grabComponenet(String handle,String type){
    var g = SparkRegistry.groups.getGroup(handle);
    if(g != null) return g.get(type);
  }

  // true : false => transformers/StringPrefixer
  static bool hasGroupString(String path){
   return SparkRegistry.groups.hasGroupString(path);
  }

  // components/component
  static void addUsingString(String path,Function n){
    return SparkRegistry.groups.addUsingString(path,n);
  }

  //transformers/StringPrefixer
  static dynamic getGroupFromString(String path){
    return SparkRegistry.groups.getGroupFromString(path);
  }

  //transformers/StringPrefixer,[id,name],{id:name}
  static dynamic generateFromString(String path,[List ops,Map a]){
    return SparkRegistry.groups.generateFromString(path,ops,a);
  }

}


class SparkFlow extends FlowAbstract{
  final metas = new hub.MapDecorator.from({'desc':'top level flowobject'});
  Network network; 

  static create(String id,[String desc]) => new SparkFlow(id,desc);

  SparkFlow(String id,[String desc]){
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
    if(!SparkRegistry.hasGroupString(paths)) return this;
    return this.network.add(SparkRegistry.generateFromString(paths,a,m),alias,n);
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

}


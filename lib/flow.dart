library flow;

import 'dart:collection';
import 'dart:async';
import 'dart:io';
import 'package:invocable/invocable.dart';
import 'package:hub/hub.dart';
import 'package:pipes/pipes.dart';
import 'package:ds/ds.dart' as d;


/*base class for flow */
abstract class FlowAbstract{
	void boot();
	void shutdown();
	void initalizeIPS();
	void addComponent();
	void addGraph();
	void removeComponent();
	void removeGraph();
}

abstract class FlowSocket{
	void bind();
	void unbind();
	void beginGroup();
	void endGroup();
	void send();
	void end();
	void close();
	void attach(FlowPort port,FlowPort m);
}

/*base class for ports*/
abstract class FlowPort{
  void connect();
  void send(data);
  void disconnect();
  void attach(FlowPort a);
  void detach(FlowPort a);
}

abstract class FlowComponent extends ExtendableInvocableBinder{
  bool _active = false;
  String description;
  String id;

  FlowComponent(this.id);
  
  bool get active => !!this._active;
  bool get inActive => !this._active;
  
}

//base class for IP (Information Packets)
abstract class FlowIP{
  dynamic get data;
  dynamic get id;
  dynamic get meta;
}

abstract class FlowNetwork{
  String id;

  FlowNetwork(this.id);
  void add(FlowComponent n,[String uniq]);
  void remove(String n);
  void connect(String m,String mport,String n,String nport);
  void disconnect(String m,String n);
}

class Socket extends FlowSocket{
  final BufferedStream stream = BufferedStream.create();
  FlowPort from,to;
  String id;
  bool _ong = false;
  bool _connected = false;
	
  static create(from,to) => new Socket(from,to);
  Socket(from,to){
    this.attach(from,to);
  }
  
  void attach(FlowPort from,FlowPort to){
    this.from = from;
    this.to = to;
    this.from.pipe.listen(this.stream.add);
    this.stream.listen(this.to.pipe.add);
    this.unbind();
  }

  void beginGroup([group]){
    if(this._ong) return;
    this._ong = true;
    this.stream.buffer();
    if(group != null) this.stream.add(group);
  }

  void endGroup([groupend]){
    if(!this._ong) return;
    if(groupend != null) this.stream.add(groupend);
    this.stream.endBuffer();
    this._ong = false;
  }
  
  void send(data){
    this.stream.add(data);
  }

  void bind(){
    this._connected = true;
    this.stream.resume();
  }

  void unbind(){
    this._connected = false;
    this.stream.pause();
  }

  void close(){
    this._connected = false;
    this.to.pipe.disconnect();
    this.from.pipe.disconnect();
    this.from = this.to = null;
  }

  bool get isConnected => !!this._connected;
  bool get isDisconnected => !this._connected;
}

class OptionPort extends FlowPort{
  final Streamable stream = Streamable.create();
  String id;
  Function _bkhandler;
  OptionPort _p;

  static create(id) => new OptionPort(id);

  OptionPort(this.id);

  void connect(){
    this.stream.resume();
  }

  void disconnect(){
    this.stream.pause();
  }

  void send(data){
    this.stream.add(data);
  }
	
  onDrain(Function n) => this.stream.onDrain(n);
  offDrain(Function n) => this.stream.offDrain(n);
  
  void attach(OptionPort a){
    this._bkhandler = this.stream.handle;
    this._p = a;
    this.stream.listen((n){
      this._p.send(n);
      this._bkhandler(n);
    });
  }

  void detach(){
    this.stream.listen(this._bkhandler);
  }
  
}

/*the channel for IP transmission on a component*/
class Port extends FlowPort{
  Streamable pipe;
  FlowSocket socket;
  String id;
  String componentID;
  
  static create(id,[cid]) => new Port(id,cid);

  Port(this.id,[cid]):super(){
    this.pipe = Streamable.create();
    this.componentID = cid;
  }
  
  void beginGroup(data){
    if(this.socket == null) return;
    this.socket.beginGroup(data);
  }

  void send(data){
    if(this.socket == null) return;
    this.connect();
    this.socket.send(data);
    this.disconnect();
  }

  void endGroup([data]){
    if(this.socket == null) return;
    this.socket.endGroup(data);
  }
  
  void listen(Function n){
    this.pipe.listen(n);
  }

  void connect(){
    if(this.socket == null) return;
    this.socket.bind();
  }

  void disconnect(){
    if(this.socket == null) return;
    this.socket.unbind();
  }
  
  void attach(FlowPort a){
    if(this.socket != null) return;
    this.socket = new Socket(this,a);
  }

  void detach(){
    if(this.socket == null) return;
    this.socket.unbind();
    this.socket.close();
    this.socket = null;
  }
  
  void pipePort(FlowPort a){
    this.listen(a.send);
  }

  bool get isConnected{
    if(this.socket == null) return false;
    return this.socket.isConnected;
  }

  bool get isDisconnected {
    if(this.socket == null) return true;
    this.socket.isDisconnected; 
  }
}


/*class for component*/
class Component extends FlowComponent{
  final meta = new MapDecorator.from({'desc':'basic description'});
  final subNetwork = new MapDecorator();
  final ports = new MapDecorator();
  final OptionPort options = OptionPort.create('option');
  String uuid;

  
  static create(String id) => new Component(id);

  Component(String id): super(id){
    this.ports.add('option',this.options);
    this.addInv('option',val: this.ports.get('option'));
  }
  
  FlowPort makePort(String id,[Port p]){
    assert(!!this.ports.add(id,(p == null ? Port.create(id) : p)));
    this.addInv(id,val: this.ports.get(id));
  }
  
  void renamePort(oldName,newName){
    if(!this.ports.has(oldName)) return;
	  var pt = this.getInv(oldName);
	  this.delInv(oldName);
    this.ports.destroy(oldName);
	  pt.id = newName;
    this.makePort(newName,pt);
  }
  
  void close(){
    this.ports.onAll((n) => n.detach());
  }
  
  void loopPorts(String v,String u){
    var from = this.ports.get(v);
    var to = this.ports.get(u);

    if(to != null && from != null){
      from.pipePort(to);
    }
  }

  String get description => this.meta.get('desc');
  FlowPort getPort(String id) => this.ports.get(id);

}

class Network extends FlowNetwork{
  final components = new d.dsGraph<FlowComponent,int>();
  final sockets = new d.dsGraph<FlowSocket,int>();
  final initialIP = d.dsList.create();

  //the graph filters
  final d.GraphFilter componentFinder = new d.GraphFilter.depthFirst((key,node,arc){
      if(node.data.uuid == key) return node;
      return null;
  });

  final d.GraphFilter socketFinder = new d.GraphFilter.depthFirst((key,node,arc){
      if(node.data.id == key) return node;
      return null;
  });


  static create(id) => new Network(id);

  Network(id): super(id){
   this.componentFinder.use(this.components);
   this.socketFinder.use(this.sockets);
  }
  
  Future get(String m){
    return this.componentFinder.filter(m).then((_){
      return _.data;
    }).catchError((e){ 
        print(e);
    });
  }

  void add(FlowComponent a,String uniqiD){
      var node = this.components.add(a);
      node.data.uuid = uniqiD;
      this.components.bind(this.components.first,node,0);
      this.components.bind(node,this.components.first,1);
  }

  void connect(String a,String aport, String b , String bport){
    Future.wait(this.componentFinder.filter(a),this.componentFinder.filter(b)).then((_){
      var from = _[0], to = _[1];
      from.data.getPort(aport).attach(to.data.getPort(bport));
      this.components.bind(from,to,1);
    }).catchError((e){
      throw e;
    });
  }


  void disconnect(String a,String b,String aport){
    Future.wait(this.componentFinder.filter(a),this.componentFinder.filter(b)).then((_){
      var from = _[0], to = _[1];
      from.data.getPort(aport).detach();
      this.components.unbind(from,to,1);
    }).catchError((e){
      print(e);
    });
  }
  
  void remove(String a){
    this.componentFinder.filter(a).then((_){
      _.data.detach();
      this.components.eject(_);
    });
  }

}

class Flow extends FlowAbstract{

  static create() => new Flow();
  Flow();
}

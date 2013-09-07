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

/*base class for component*/
abstract class FlowComponent{
	
}

abstract class FlowSocket{
	void bind();
	void unbind();
	void beginGroup();
	void endGroup();
	void send();
	void end();
	void close();
	void attachPort(FlowPort port);
	void detachPort();
}

/*base class for stream*/
abstract class FlowStream{
    void push();
}

/*base class for ports*/
abstract class FlowPort extends ExtendableInvocableBinder{
  void bind(FlowPort to);
  void unbind(FlowPort to);
  void attach(FlowPort a);
  void unattach(FlowPort a);
}

//base class for IP (Information Packets)
abstract class FlowIP{
  dynamic get data;
  dynamic get id;
  dynamic get meta;
}

class Flow extends FlowAbstract{

  static create() => new Flow();
  Flow();
}

class IP extends FlowIP{
  final zone = new MapDecorator();

  static create(id,Map meta,data) => new IP(id,meta,data);
  IP(id,meta,data){
    this.zone.add('data',data);
    this.zone.add('id',id);
    this.zone.add('meta',new MapDecorator.from(meta));
  }

  dynamic get Meta => this.zone.get('meta');
  dynamic get Data => this.zone.get('data');
  dynamic get ID => this.zone.get('id');

}

class GroupIP extends FlowIP{

}

class Socket extends FlowSocket{
  final BufferedStream streams = BufferedStream.create();
  FlowPort from,to;
  String delimiter = '/';
  bool _ong = false;
  bool _connected = false;
	
  static create(from,to) => new Socket(from,to);
  Socket(this.from,this.to);

  void beginGroup(group){
    if(this._ong) return;
    this._ong = true;
    this.streams.buffer();
    this.streams.add(group);
  }

  void endGroup([groupend]){
    if(!this._ong) return;
    if(groupend != null) this.streams.add(groupend);
    this.streams.endBuffer();
    this._ong = false;
  }
  
  void send(data){
    this.streams.add(data);
  }

  void bind(){
    this._connected = true;
  }

  void unbind(){
    this._connected = false;
  }

  void close(){
    
  }
}

/* stream class main class*/
class Stream extends FlowStream{
  Pipe pipe;

	static create(String id,{num max:100}){
    return new Stream(id:id, max:max);
  }

  Stream({ String id, num max }){
    this.pipe = 
  }

}
	
/*class for component*/
class Component extends FlowComponent{
  
  static create() => new Component();
  Component();
}

/*the channel for IP transmission on a component*/
class Port extends FlowPort{
  StreamController stream = new StreamController();
  String id;
  
  static create(id) => new Port(id);

  Port(this.id):super(){
    this.alias('add',stream.add);
    this.alias('listen',stream.stream.listen);
    this.binder.lock();
  }

}

class FlowNetwork{

  static create() => new FlowNetwork();

}

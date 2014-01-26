library sparkflow.transport;

import 'dart:async';
import 'package:hub/hub.dart' as hub;
import 'package:sparkflow/sparkflow.dart';
import 'package:streamable/streamable.dart';

abstract class BaseTransport{
	hub.MapDecorator options;
	dynamic context;

	BaseTransport(Map ops){
		this.options = new hub.MapDecorator.from(ops);
		this.context = null;
	}

	void send(protocol,topic,payload,context);

	void receive(protocol,topic,payload,context);
}

abstract class BaseProtocol{
	BaseTransport transport;

	BaseProtocol(this.transport);

	void send(topic,payload,context);

	void receive(topic,payload,context);
}

class ComponentProtocol extends BaseProtocol{
	ComponentsList componentList;

	static create(t,l) => new ComponentProtocol(t,l);

	ComponentProtocol(t,l): super(t){
		this.componentList = l;
	}

	void send(topic,payload){
		this.transport.send('component',topic,payload,context);
	}

	void listComponent(context){
		this.componentList.onAll((k,v){
			this.sendComponent(k,v,context);
		});
	}

	void sendComponent(String component,FlowComponent instance,context){
		var portclass = instance.getPortClassList();
		var load = {
			'name': component,
			'description': instance.metas.get('desc'),
			//'uuid': instance.metas.get('uuid'),
			'inports': portclass['in'],
			'outports': portclass['out'],
			'errports': portclass['err'],
			'optionports': portclass['option'],
			'icon': 'blank'
		};

		this.send('component',load,context);
	}

	void registerNetwork(id,graph,context){

	}

	void receive(topic,payload,context){
		if(topic == 'list') this.listComponent(context);
	}
	
}

class NetworkProtocol extends BaseProtocol{
	Network net;

	static create(t,n) => new NetworkProtocol(t,n);
	
	NetworkProtocol(t,n): super(t){
		this.net = n;
	}

	void send(topic,payload,context){
		this.transport.send('network',topic,payload,context);
	}
	
	void startNetwork(payload,context){
		this.net.boot();
	}

	void pauseNetwork(payload,context){
		this.net.boot();
	}

	void stopNetwork(payload,context){
		this.net.boot();
	}

	void addEdge(payload,context){

	}

	void removeEdge(payload,context){

	}

	void addNode(payload,context){

	}

	void removeNode(payload,context){

	}

	void renameNode(payload,context){

	}

	void addInitial(payload,context){

	}

	void removeInitial(payload,context){

	}

	void receive(topic,payload,context){
		if(topic == 'start') this.startNetwork(payload,context);
		if(topic == 'stop') this.stopNetwork(payload,context);
		if(topic == 'pause') this.pauseNetwork(payload,context);
		if(topic == 'addEdge') this.addEdge(payload,context);
		if(topic == 'removeEdge') this.removeEdge(payload,context);
		if(topic == 'addNode') this.addNode(payload,context);
		if(topic == 'removeNode') this.removeNode(payload,context);
		if(topic == 'renameNode') this.renameNode(payload,context);
		if(topic == 'addInitial') this.addInitial(payload,context);
		if(topic == 'removeInitial') this.removeInitial(payload,context);
	}
}


class SparkFlowProtocol extends BaseProtocol{
	ComponentProtocol com;
	NetworkProtocol net;
	SparkFlow  flow;

	SparkFlowProtocol(SparkFlow sf,BaseTransport t): super(t){
		this.com = ComponentProtocol.create(t,flow.tree);
		this.net = NetworkProtocol.create(t,flow.network);
	}
}

class SparkflowTransport extends BaseTransport{
	var components,network;

	static create([Map options]) => new SparkflowTransport(options);

	SparkflowTransport([Map ops]): super(Hub.switchUnless(ops,{})){
		this.components = ComponentProtocol.create(this);
		this.network = NetworkProtocol.create(this);
	}

	void send(protocol,topic,payload,context);

	void receive(protocol,topic,payload,context){
		if(protocol == 'graph') return this.network.receive(topic,payload,context);
		if(protocol == 'network') return this.network.receive(topic,payload,context);
		if(protocol == 'component') return this.components.receive(topic,payload,context);
	}
}

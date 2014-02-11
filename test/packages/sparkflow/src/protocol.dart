part of sparkflow;

abstract class BaseTransport{
  hub.MapDecorator options;

  BaseTransport(Map ops){
    this.options = new hub.MapDecorator.from(ops);
  }

  void send(protocol,topic,payload);

  void receive(protocol,topic,payload);
}

abstract class BaseProtocol{
  BaseTransport transport;

  BaseProtocol(this.transport);

  void send(topic,payload);

  void receive(topic,payload);
}


abstract class NetworkProtocol extends BaseProtocol{
  Network net;
  
  NetworkProtocol(t,n): super(t){
    this.net = n;
  }

  void send(topic,payload){
    this.transport.send('network',topic,payload);
  }
  
  void startNetwork(payload);

  void freezeNetwork(payload);

  void shutdownNetwork(payload);

  void connect(payload);

  void disconnect(payload);

  void addComponent(payload);

  void removeComponent(payload);

  void renameComponent(payload);

  void addComponentInitial(payload);

  void removeComponentInitial(payload);

  void receive(command,payload){
    if(command == 'startNetwork') this.startNetwork(payload);
    if(command == 'shutdownNetwork') this.shutdownNetwork(payload);
    if(command == 'freezeNetwork') this.freezeNetwork(payload);
    if(command == 'connect') this.connect(payload);
    if(command == 'disconnect') this.disconnect(payload);
    if(command == 'addComponent') this.addComponent(payload);
    if(command == 'removeComponent') this.removeComponent(payload);
    if(command == 'renameComponent') this.renameComponent(payload);
    if(command == 'addComponentInitial') this.addComponentInitial(payload);
    if(command == 'removeComponentInitial') this.removeComponentInitial(payload);
  }
}


var payloadValidator = hub.Funcs.matchListConditions([(v){
    return v.containsKey('id');
  },(v){ 
    return v.containsKey('uid'); 
}]);

class ComponentProtocol extends BaseProtocol{

  static create(t) => new ComponentProtocol(t);

  ComponentProtocol(t): super(t);

  // void addComponent(payload){
  //   payloadValidator(payload).then((p){
  //     if(!p.containsKey('instance')) return;
  //     this.componentList.add(p['uid'],p['instance']);
  //   }).catchError((e){});
  // }

  // void removeComponent(payload){
  //   payloadValidator(payload).then((p){
  //     this.componentList.remove(p['uid']);
  //   }).catchError((e){});
  // }
  
  void send(topic,payload){
    this.transport.send('components',topic,payload);
  }
  
  void listComponents(){
    
  }
  
  void receive(command,payload){
     if(hub.Valids.iS(command,"list")) return this.listComponents();
     // if(Valids.iS(command,"addComponent")) return this.addComponent(payload);
     // if(Valids.iS(command,"removeComponent")) return this.removeComponent(payload);
  }

}

class SparkFlowNetworkProtocol extends NetworkProtocol{
  
  static create(t,n) => new SparkFlowNetworkProtocol(t,n);
  
  SparkFlowNetworkProtocol(t,n): super(t,n);

  void startNetwork(payload){
    this.net.boot();
  }
  
  void switchNetwork(Network t){
  	this.net = t;
  }

  void freezeNetwork(payload){
    if(this.net.isFrozen) return null;
    if(this.net.isAlive){
      this.net.whenAlive.then((net){
        this.net.boot();
      });
      return null;
    }

    this.net.freeze();
  }

  void shutdownNetwork(payload){
    if(this.net.isDead) return null;

    if(this.net.isFrozen){
      this.net.whenFrozen.then((net){
        this.net.shutdown();
      });
      return null;
    }

    if(this.net.isAlive){
      this.net.whenAlive.then((net){
        this.net.shutdown();
      });
      return null;
    }
    
    this.net.shutdown();
  }

  void connect(payload){

  }

  void disconnect(payload){

  }

  void addComponent(payload){

  }

  void removeComponent(payload){

  }

  void renameComponent(payload){

  }

  void addComponentInitial(payload){

  }

  void removeComponentInitial(payload){

  }
  
}


abstract class MessageRuntime{
  final options = hub.Hub.createMapDecorator();
  Streamable errMessages,outMessages,inMessages;
  dynamic root;

  MessageRuntime(this.root,[bool catchExceptions]){
    this.options.add('catchExceptions',(catchExceptions == null ? false : catchExceptions));

    this.outMessages = Streamable.create();
    this.inMessages = Streamable.create();
    this.errMessages = Streamable.create();
  }

  void init(){
    this.bindOutStream();
    this.bindInStream();
    if(!!this.options.get('catchExceptions')) this.bindErrorStream();
  }

  void send(protocol,command,payload,target){

    var data = {
      'protocol': protocol,
      'command': command,
      'payload': payload,
    };

    this.outMessages.emit({'target': target, 'message': data });
  }

  void bindInStream();
  void bindErrorStream();
  void bindOutStream();

}

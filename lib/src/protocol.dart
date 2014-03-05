part of sparkflow;

var payloadValidator = hub.Funcs.matchListConditions([(v){
    return v.containsKey('id');
}]);

var initialValidator = hub.Funcs.matchListConditions([
(v){ return v.containsKey('id'); },
(v){ return v.containsKey('data'); }]);

var componentValidator = hub.Funcs.matchListConditions([
(v){ return v.containsKey('id'); },
(v){ return v.containsKey('instance') || v.containsKey('path'); }]);

var connectionsValidator = hub.Funcs.matchListConditions([
(v){ return v.containsKey('from'); },
(v){ return v.containsKey('to'); },
(v){ return v.containsKey('fromPort'); },
(v){ return v.containsKey('toPort'); }]);

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

abstract class BaseNetworkProtocol extends BaseProtocol{
  Network net;
  
  BaseNetworkProtocol(n,t): super(t){
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


class ComponentProtocol extends BaseProtocol{
  var component;
  
  static create(c,t) => new ComponentProtocol(c,t);

  ComponentProtocol(c,t): super(t){
     this.switchComponent(c);
  }
  
  void switchComponent(FlowComponent c){
     this.component = c;
  }
  
  void send(topic,payload){
    this.transport.send('components',topic,payload);
  }
  
  void enableSubnet(payload){
     if(payload.containsKey('subnet') && payload['subnet'] is Network)
       this.component.useSubnet(payload['subnet']);
     else this.component.enableSubnet();
  }
  
  void removeSubnet(payload){
     this.component.disableSubnet();
  }
  
  void packet(payload){
    
     hub.Funcs.when(hub.Valids.match(payload['type'],'data'),(){
        this.component.send(payload['data']);
     });
     
     hub.Funcs.when(hub.Valids.match(payload['type'],'beginGroup'),(){
        this.component.beginGroup(payload['data']);
     });
     
     hub.Funcs.when(hub.Valids.match(payload['type'],'endGroup'),(){
        this.component.endGroup(payload['data']);     
     });
  }
 
    
  void boot(payload){
    this.component.boot();
  }
 
  void freeze(payload){
    this.component.freeze();   
  }
  
  void shutdown(payload){
   this.component.shutdown();
  }
  
  void receive(command,payload){
     if(hub.Valids.match(command,"removeSubnet")) return this.removeSubnet(payload);
     if(hub.Valids.match(command,"enableSubnet")) return this.enableSubnet(payload);     
     if(hub.Valids.match(command,"boot")) return this.boot(payload);
     if(hub.Valids.match(command,"freeze")) return this.freeze(payload);
     if(hub.Valids.match(command,"shutdown")) return this.shutdown(payload);     
     if(hub.Valids.match(command,"packet")) return this.packet(payload);     
     //if(hub.Valids.match(command,"addIIP")) return this.addIIP(payload);
     //if(hub.Valids.match(command,"removeIIP")) return this.removeIIP(payload);
     //if(hub.Valids.match(command,"beginGroup")) return this.beginGroup(payload);     
     //if(hub.Valids.match(command,"endGroup")) return this.endGroup(payload);     
  }

}

class NetworkProtocol extends BaseNetworkProtocol{
  
  static create(n,t) => new NetworkProtocol(n,t);
  
  NetworkProtocol(n,t): super(n,t);

  void startNetwork(payload){
    this.net.boot();
  }
  
  void switchNetwork(Network t){
  	this.net = t;
  }

  void freezeNetwork(payload){
    payloadValidator(payload).then((n){
    
        if(this.net.isFrozen) return null;
        if(this.net.isAlive){
          this.net.whenAlive.then((net){
          this.net.boot();
        });
        return null;
        }

        this.net.freeze();    
        
    }).catchError((e){});

  }
              
  void shutdownNetwork(payload){
    payloadValidator(payload).then((n){
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
    }).catchError((e){
    
    });

  }

  void connect(payload){
      connectionsValidator(payload).then((n){
        
        if(n.containsKey('persist') && n['persist'] == true) 
          return this.net.ensureBinding(n['from'],n['fromPort'],n['to'],n['toPort'],n['socketid']);
        
        return this.net.looseBinding(n['from'],n['fromPort'],n['to'],n['toPort'],n['socketid']);
        
      }).catchError((e){});
  }

  void disconnect(payload){
      connectionsValidator(payload).then((n){
        if(n.containsKey('persist') && n['persist'] == true) 
          return this.net.ensureUnbinding(n['from'],n['fromPort'],n['to'],n['toPort'],n['socketid']);
        
        return this.net.looseUnbinding(n['from'],n['fromPort'],n['to'],n['toPort'],n['socketid']);       
      }).catchError((e){});
  }

  void addComponent(payload){
      payloadValidator(payload).then((n){
        
        if(n.containsKey('instance') && n['instance'] is FlowComponent)
           return this.net.addComponentInstance(n['instance'],n['id'],n['fn']);
           
        return this.net.add(n['path'],n['id'],n['fn']);
        
      }).catchError((e){});
  }

  void removeComponent(payload){
      payloadValidator(payload).then((n){
      
          this.net.remove(n['id']).then((n){}).catchError((e){
          
          });
          
      }).catchError((e){});
  }

  void renameComponent(payload){
      payloadValidator(payload).then((n){
      
        this.net.filter(n['id']).then((n){
        
        }).catchError((e){
        
        });
        
      }).catchError((e){});
  }

  void addComponentInitial(payload){
      initialValidator(payload).then((n){
      
        this.net.addInitial(n['id'],n['data']);
        
      }).catchError((e){});
  }

  void removeComponentInitial(payload){
      payloadValidator(payload).then((n){
          this.net.removeInitial(n['id'],n['fn']);          
      }).catchError((e){});
  }
  
  void listComponents(payload){
      //this.transport.send('components','components',this.net.componentsMeta);
      this.send('components',this.net.componentsMeta);
  }
  
  void receive(command,payload){
     if(hub.Valids.match(command,'listComponents')){ 
        this.listComponents(payload);
        return null;
     }
     super.receive(command,payload);
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

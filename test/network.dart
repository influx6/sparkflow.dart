library flow.specs;

import 'package:sparkflow/sparkflow.dart';

void main(){
  
  Component.registerComponents();
  
  var network = Network.create('example');
  network.createDefaultPorts();
  network.networkStream.pause();
  
  var loop = Component.create('loop');
  loop.createDefaultPorts();
  loop.loopPorts('in:in','out:out');
    
  var costa = Component.create('costa');
  costa.createDefaultPorts();
  
  var cosmo = Component.create('cosmo');
  cosmo.createDefaultPorts();
    
  network.addComponentInstance(loop,'loopback');
  network.addComponentInstance(costa,'costa');
  network.addComponentInstance(cosmo,'cosmo');
  
  network.filter('cosmo').then((_){
    assert(_.data.UID == cosmo.UID);
  });
  
  //order goes component who wants to connect to component port with port
  network.connect('costa','loopback','in:in','out:out');

  network.freeze();
  //listen to info streams for update
  network.networkStream.on((n){
    print('#Updates: \n $n \n');
  });

  network.connectionStream.on((n){
    print('#Connections: \n $n \n');
  });

  network.iipStream.on((n){
    print('#iipStreams: \n $n \n');
  });

  network.errorStream.on((n){
    print('#errorStream: \n $n \n');
  });

  network.componentStream.on((n){
    print('#componentStream: \n $n \n');
  });

  network.boot();
}

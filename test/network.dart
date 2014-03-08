library flow.specs;

import 'package:sparkflow/sparkflow.dart';

void main(){
  
  var network = Network.create('example');

  network.networkStream.pause();
  
  var loop = Component.create('loop');
  loop.loopPorts('inports:in','outports:out');
  
  var costa = Component.create('costa');

  var cosmo = Component.create('cosmo');

  network.addComponentInstance(loop,'loopback');
  network.addComponentInstance(costa,'costa');
  network.addComponentInstance(cosmo,'cosmo');
  
  network.filter('cosmo').then((_){
    assert(_.data.UID == cosmo.UID);
  });
  
  //order goes component who wants to connect to component port with port
  network.connect('costa','loopback','inports:in','outports:out');

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

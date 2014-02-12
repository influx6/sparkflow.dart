library flow.specs;

import 'package:sparkflow/sparkflow.dart';

void main(){
  
  var network = Network.create('example');

  network.networkStream.pause();
  
  var loop = Component.create('loop');
  loop.renamePort('in','suck');
  loop.renamePort('out','spill');
  loop.loopPorts('suck','spill');
  
  var costa = Component.create('costa');

  var cosmo = Component.create('cosmo');

  network.addComponentInstance(loop,'loopback');
  network.addComponentInstance(costa,'costa');
  network.addComponentInstance(cosmo,'cosmo');
  
  network.filter('cosmo').then((_){
    assert(_.data.UID == cosmo.UID);
  });
  
  //order goes component who wants to connect to component port with port
  network.connect('costa','loopback','in','out');

  network.freeze();
  //listen to info streams for update
  var buffer = new StringBuffer();
  network.networkStream.on((n){
    print('#Updates: \n $n \n');
    buffer.clear();
  });

  network.boot();
}

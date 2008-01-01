library flow.specs;

import 'package:sparkflow/sparkflow.dart';

void main(){
  
  var toPort = Socket.create();
  var fromPort = Socket.create();
 
  toPort.bindSocket(fromPort);

  fromPort.on((n){
    print('#fromPort recieves: $n');
  });
  
  toPort.forceCondition((n){ return (n is String); });
  toPort.forceCondition((n){ return (n != 'sunday'); });

  toPort.send('think');
  toPort.send('straight');
  toPort.send('my');
  
  toPort.send(1);

  toPort.beginGroup('<people>');
  toPort.send('sunday');
  toPort.send('!');
  toPort.endGroup('</people>');
  

  toPort.unbindSocket(fromPort);

  toPort.send('not-recieved!');
}

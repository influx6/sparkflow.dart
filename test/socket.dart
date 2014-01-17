library flow.specs;

import 'package:sparkflow/sparkflow.dart';

void main(){
  
  var toPort = Socket.create();
  var fromPort = Socket.create();
 
  toPort.bindSocket(fromPort);

  fromPort.on((n){
    print('#fromPort recieves: $n');
  });
  
  toPort.setDelimiter('|');
  toPort.enableDelimiter();

  toPort.send('think');
  toPort.send('straight');
  toPort.send('my');
  toPort.beginGroup('<people>');
  toPort.send('people');
  toPort.send('!');
  toPort.endGroup('</people>');

  toPort.unbindSocket(fromPort);

  toPort.send('not-recieved!');
}

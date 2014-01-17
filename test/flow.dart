library flow.specs;

import 'package:sparkflow/sparkflow.dart';

void main(){
  

	var toPort = Port.create('out');
	var fromPort = Port.create('in');

	fromPort.bindPort(toPort);

	toPort.tap((n){
	   print('#toPort recieves: $n');
	});

	fromPort.setDelimiter('');
	fromPort.enableDelimiter();

	fromPort.send('love');
	fromPort.beginGroup('<note>');
	fromPort.send('i need a woman who heart will be mine!');
	fromPort.endGroup('</note>');

	fromPort.disableDelimiter();

	fromPort.send('think');
	fromPort.send('straight');
	fromPort.send('my');
	fromPort.send('people');

	fromPort.unbindPort(toPort);

	fromPort.send('!');


}

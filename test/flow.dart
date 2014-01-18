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
  
	//transformer will will always apply to streams even when cherry picking who to send to
	fromPort.dataTransformer.on((n){
	  return n+"::";
	});
	
	fromPort.send('someone');

	// this will automaitcally send to the subscriber socket at alias/id 1 but transformation of parent streams
	// will still apply regardless
	fromPort.send('think','1');
	//clear out the transformer
	fromPort.dataTransformer.freeListeners();
	
	fromPort.send('straight');
	fromPort.send('my');
	fromPort.send('people');

	fromPort.unbindPort(toPort);

	fromPort.send('!');
  

}

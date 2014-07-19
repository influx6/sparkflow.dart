library flow.specs;

import 'package:sparkflow/sparkflow.dart';

void main(){
  

	var toPort = Port.create('out',{
      'name':'toPort',
  });
	var fromPort = Port.create('in',{
      'name':'fromPort',
  });

	fromPort.bindPort(toPort);

        toPort.tapEnd((n){
          print('endEvent triggered!');
        });

	toPort.tap((n){
	   print('#toPort recieves: $n');
	});

        fromPort.tapEnd((n){
          print('ended well $n');
        });

	fromPort.send('love');
	fromPort.beginGroup('<note>');
	fromPort.send('i need a drink!');
	fromPort.endGroup('</note>');

  
	//transformer will will always apply to streams even when cherry picking who to send to
	fromPort.mixedTransformer.on((n){
	  n.data = n.data+"::";
    return n;
	});
	
	fromPort.send('someone');

	// this will automaitcally send to the subscriber socket at alias/id 1 but transformation of parent streams
	// will still apply regardless
	fromPort.send('think','1');
	//clear out the transformer
	//fromPort.mixedTransformer.freeListeners();
	
	fromPort.send('straight');
	fromPort.send('my');
	fromPort.send('people');


	fromPort.unbindPort(toPort);

	fromPort.send('!');

        fromPort.close();
}

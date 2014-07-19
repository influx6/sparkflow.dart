library flow.specs;

import 'package:sparkflow/sparkflow.dart';
import 'package:sparkflow/components/transformers.dart';
import 'package:sparkflow/components/unmodifiers.dart';

void main(){
  
  var rep1 = Repeater.create();
  var rep2 = StringPrefixer.create();
  var cosmo = Component.create('cosmo');

  //lets loop cosmo in port to its outport,a basic repeater 
  cosmo.loopPorts('in:in','out:out');

  var network = Network.create("testBed");
  
  network.addComponentInstance(rep1,'repeater',(meta){
  	//print('internal initial socket: ${meta.toString().split(',').join('\n')}');
  });
    
  network.addComponentInstance(rep2,'prefixer',(meta){
  	//print('internal initial socket: ${meta.toString().split(',').join('\n')}');

  	//attach the IIP to the component's option port
  	//meta.socket.attachPort(meta.component.port('option'));
  });

  network.addComponentInstance(cosmo,'cosmo',(meta){
  	//print('internal initial socket: ${meta.toString().split(',').join('\n')}');
  });

  /*order goes:
  	1: component who wants to connect
  	2: port name of component who wants to connect
  	3: component to be connected to
  	4: port name of component to be connected to
	Optional:
  	5: a tag name to be giving the socket,incase of selective message eg. send('data','1' or 'goba');
  	6: bool value to dictate it uses breadthfirst search technique instead of the default depthfirst
  */
  //prefixer wants to connect its 'in' port to repeaters 'out'
  //repeater wants to connect its 'out' port to cosmo 'in' port;;
  //needed due to the nature of network connections using futures
  network
  .connect('prefixer','in:in','repeater','out:out')
  .connect('repeater','in:in','cosmo','out:out',null,true).boot().then((_){
    assert(_ == network);
	  //its not always necessary for a networks in and out to be connect,but there are cases eg composite components
	  //where data must be fed into the network for its components to process
	      
	  //we will connect networks in port (nin) to cosmo 'in' port
	  network.nin.bindPort(cosmo.port('in:in'));
	  // tap into networks out port 'nout' to see what comes out

	  network.nout.tap((n){
	  	print('network spouting: $n');
	  });

	  //only the prefixer component requires data feed into it before its operational,so add a IIP data for it,
	  //you can always add another iip data to change the prefix;
	  network.addInitial('prefixer','network::');


//	  cosmo.port('in').tap((n){
//	  	print('cosmo in: $n');
//	  });
//
//	  cosmo.port('out').tap((n){
//	  	print('cosmo out: $n');
//	  });
//
//	  rep1.port('in').tap((n){
//	  	print('repeater in: $n');
//	  });
//
//	  rep1.port('out').tap((n){
//	  	print('repeater out: $n');
//	  });
//
//	  rep2.port('in').tap((n){
//	  	print('prefixer in: $n');
//	  });
//
//	  rep2.port('out').tap((n){
//	  	print('prefixer out: $n');
//	  });


	  rep2.port('out:out').bindPort(network.nout);

 	  network.nin.send('sanction'); 
    
 	  return _;
  }).catchError((e){
  	throw e;
  });
  
  network.whenAlive.then((_){
    network.freeze();
    
    network.addInitial('prefixer','pre::');
   
    network.whenFrozen.then((_){
      network.nin.send('frozen!');
      network.boot();
      
      network.networkStream.on((m){
        print('update: \n $m \n');
      });
    });
    

  });

//  this fires first and the other of data changes
//  network.freeze();
//  
//  
//  network.addInitial('prefixer','pre::');
//  
//  network.whenFrozen.then((_){
//    print('isFrozen!');
//    network.nin.send('frozen!');
//    network.boot();
//    
//    network.infoStream.tap((m){
//      print('update: \n $m \n');
//    });
//  });
  
}

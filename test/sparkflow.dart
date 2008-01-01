library sparkflow.protocol;


import 'package:sparkflow/sparkflow.dart';

void main(){
  
          assert(SparkRegistry != null);
          
          Component.registerComponents();
           
	var sf = SparkFlow.create("example.basic", "standard sf object to use");
  	
  	//SparkFlow.use: Arguements
  	// 1. path of the component in the registry(name of group / name of component)
  	// 2. alias for component 
  	// 3. List of arguments
  	// 4. Map for named arguments
  	// 5. Function for extra duties
  	// note: now all components automatically get their options port attached to the IIPSocket(no-overrides)
  	
	sf.use('components/component','cosmo',null,null,(m){
	  m.createDefaultPorts();
            m.port('in:in').tap((n){ print('cosmo-in:$n');});
            m.port('out:out').tap((n){ print('cosmo-out:$n');});
	})
	
	//cosmo in will feed cosmo out
          sf.ensureBinding('cosmo','out:out','cosmo','in:in');
	
	//network(*) in will feed cosmo's in
	sf.ensureBinding('cosmo','in:in','*','in:in');
	
	//cosmo out will feed network out
	sf.ensureBinding('*','out:out','cosmo','out:out');


	sf.network.connectionStream.on((e){
	   print('connection#${e}');
	}); 

	sf.onAlive((net){
		print('booting connections!');
	});

	sf.onDead((net){
		print('shutdowing!');
	});

	sf.boot().then((_){
	   	  
		_.port('out:out').tap((n){
			  print('network spouting: $n');
		});

		_.addInitial('stringer','network::');

		_.port('in:in').send('sanction'); 

	});
	
	
 
	
}

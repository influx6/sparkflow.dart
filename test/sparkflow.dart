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
		call:
			UnModifiers.registerComponents();
		to add the sets of components to the global SparkRegistry and hence be able to address them in Sparkflow
			 
		class UnModifiers{

			static void registerComponents(){
				SparkRegistry.register("unModifiers", 'Repeater', Repeater.create);
			}

		}

		class Repeater extends Component{

			static create() => new Repeater();

			Repeater(): super("Repeater"){
				this.meta('desc','a simple synchronous repeater component');
				this.loopPorts('in','out');
			}

		}
  
  
	  	this is a necessity and should be declared either as a static function in the class,to 
	  	add the necessary components to the SparkRegistery,unforunately there is no easy way
	  	to automatically run this once a library is imported;
	*/ 

	Components.registerComponents();
  
	var sf = SparkFlow.create("example.basic", "standard sf object to use");
  	
  	//SparkFlow.use: Arguements
  	// 1. path of the component in the registry(name of group / name of component)
  	// 2. alias for component 
  	// 3. List of arguments
  	// 4. Map for named arguments
  	// 5. Function for extra duties
  	// note: now all components automatically get their options port attached to the IIPSocket(no-overrides)
  	
	sf..use('transformers/StringPrefixer','stringer')
	..use('components/component','cosmo',null,null,(m){
      m.port('in:in').tap((n){ print('cosmo-in:$n');});
      m.port('out:out').tap((n){ print('cosmo-out:$n');});
	})
	..use('unModifiers/Repeater','repeater');
  
	//repeaters-out will feed stringers in
	sf.ensureBinding('stringer','in:in','repeater','out:out');
	//cosmo out will feed repeaters in
	sf.ensureBinding('repeater','in:in','cosmo','out:out');
	//cosmo in will feed cosmo out
    sf.ensureBinding('cosmo','out:out','cosmo','in:in');
	//network(*) in will feed cosmo's in
	sf.ensureBinding('cosmo','in:in','*','in:in');
	//cosmo out will feed network out
	sf.ensureBinding('*','out:out','stringer','out:out');


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

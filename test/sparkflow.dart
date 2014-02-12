library sparkflow.protocol;


import 'package:sparkflow/sparkflow.dart';
import 'package:sparkflow/components/unmodifiers.dart';
import 'package:sparkflow/components/transformers.dart';

void main(){
  
  assert(SparkRegistry != null);

	/*
		Due to the current state of dynamic loading of coding ,beyond the use of defferedlibrary
		or using spawnURL and then transporting the loading objects from the spawned isolate (does not work in js),
		a simplified method was choosen where a library defines its components and provides a static method,where
		it registers them up into the SparkRegistry which is a global class with static objects and functions, and is used
		by the Sparkflow class to grab the components,so its a very important,do not miss it type of thing.

		I would prefer a simplified,automatically register the functions,but unlike JS we cant just run a function off in a 
		class file,so a alternate method was needed,if you wish to write your own components ensure to provide something similar
		to this to register up the components for global access by SparkFlow.
		Note: there is no way around it!

		Example: #from the /lib/components/unmodifiers.dart

		library sparkflow.unmodifiers;

		import 'package:hub/hub.dart';
		import 'package:sparkflow/sparkflow.dart';

		Feel free to defined yours as you prefer,either as this,or a static method in the Repeater class (a better option if its just one component),
		or as a global static function,just ensure to note it in the README.md or any viable documentation,with this when we load this library we simple
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

	Component.registerComponents();
	UnModifiers.registerComponents();
	Transformers.registerComponents();
  
	var sf = SparkFlow.create("example.basic", "standard sf object to use");
  	
  	//SparkFlow.use: Arguements
  	// 1. path of the component in the registry(name of group / name of component)
  	// 2. alias for component 
  	// 3. List of arguments
  	// 4. Map for named arguments
  	// 5. Function for extra duties
  	// note: now all components automatically get their options port attached to the IIPSocket(no-overrides)
  	
	sf..use('transformers/StringPrefixer','stringer',null,null,(m){
//    m.port('in').tap((n){ print('stringer-in:$n');});
//    m.port('out').tap((n){ print('stringer-out:$n');});
  })
	..use('components/component','cosmo',null,null,(m){
//      m.port('in').tap((n){ print('cosmo-in:$n');});
//      m.port('out').tap((n){ print('cosmo-out:$n');});
	})
	..use('unModifiers/Repeater','repeater',null,null,(m){
//      m.port('in').tap((n){ print('repeater-in:$n');});
//      m.port('out').tap((n){ print('repeater-out:$n');});
  });
  
	//repeaters-out will feed stringers in
	sf.ensureBinding('stringer','in','repeater','out');
	//cosmo out will feed repeaters in
	sf.ensureBinding('repeater','in','cosmo','out');
	//cosmo in will feed cosmo out
    sf.ensureBinding('cosmo','out','cosmo','in');
	//network(*) in will feed cosmo's in
	sf.ensureBinding('cosmo','in','*','in');
	//cosmo out will feed network out
	sf.ensureBinding('*','out','stringer','out');


	sf.network.connectionStream.on((e){
	  // print('connection#${e}');
	}); 

	sf.onAlive((net){
//		print('booting connections!');
	});

	sf.onDead((net){
		print('shutdowing!');
	});

	sf.boot().then((_){
	   	  
		_.port('out').tap((n){
			  print('network spouting: $n');
		});

		_.addInitial('stringer','network::');

		_.port('in').send('sanction'); 

	});
	
	
 
	
}
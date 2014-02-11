library sparkflow.timers;

import 'package:hub/hub.dart';
import 'package:sparkflow/sparkflow.dart';

//this is a necessity and should be declared either as a static function in the class,to 
//add the necessary components to the SparkRegistery,unforunately there is no easy way
//to automatically run this once a library is imported;
class Timers{
  
  static void registerComponents(){
    SparkRegistry.register("transformers", 'StringPrefixer', StringPrefixer.create);
  }
  
}

class RunTimeOut extends Component{
	Timer handler;
	
	static create() => new RunTimeOut();

	RunTimeOut(){
		this.meta('desc','sends the ip it receives at a timeout set by a number it gets from its option port');
		this.init();
	}

	void init(){

		var hin = this.port('in'),
			hout = this.port('out'),
			herr = this.port('err'),
			hop = this.port('option');

		hop.tap((n){
			if(!Valids.isNumber(n)) return herr.send(new Exception('$n is not a type of number!'));
		});
	}
}
library sparkflow.timers;

import 'package:hub/hub.dart';
import 'package:sparkflow/sparkflow.dart';

//this is a necessity and should be declared either as a static function in the class,to 
//add the necessary components to the SparkRegistery,unforunately there is no easy way
//to automatically run this once a library is imported;
class Timers{
  
  static void registerComponents(){
    SparkRegistry.register("Timers", 'RunTimeOut', RunTimeOut.create);
    SparkRegistry.register("Timers", 'RunInterval', RunInterval.create);
  }
  
}

class RunTimeOut extends Component{
	Timer handler;
	int timeout;

	static create() => new RunTimeOut();

	RunTimeOut(){
		this.meta('desc','sends ip off at a specified time in ms!');
		this.init();
	}

	void init(){

		var hin = this.port('in'),
			hout = this.port('out'),
			herr = this.port('err'),
			hop = this.port('option');

		hop.tap((n){
			if(!Valids.isNumber(n)) return herr.send(new Exception('$n is not a type of number!'));
			this.createTimer(n);
		});

		hin.dataDrained.on((n){ hin.disconnect(); });
		
		hop.dataDrained.once((n){
			hin.bindPort(hout);
			hin.pause();
		});


	}

	void createTimer(int n){
		if(Valids.exists(this.handler)) this.handler.cancel();
		this.timeout = n;
		this.handler = new Timer(new Duration(milliseconds: this.timeout),(){
			this.port('in').connect();
		});
	}

}


class RunInterval extends RunTimeOut{

	static create() => new RunInterval();

	RunInterval() : super(){
		this.meta('desc','delivers an ip every interval');
	}

	void createTimer(int n){
		if(Valids.exists(this.handler)) this.handler.cancel();
		this.timeout = n;
		new Timer.periodic(new Duration(milliseconds: this.timeout),(timer){
			this.handler = timer;
			this.port('in').connect();
		});
	}
}
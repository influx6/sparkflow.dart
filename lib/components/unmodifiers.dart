library sparkflow.unmodifiers;

import 'package:hub/hub.dart';
import 'package:sparkflow/sparkflow.dart';


//this is a necessity and should be declared either as a static function in the class,to 
//add the necessary components to the SparkRegistery,unforunately there is no easy way
//to automatically run this once a library is imported;
class UnModifiers{
  
  static void registerComponents(){
    SparkRegistry.register("unModifiers", 'Repeater', Repeater.create);
    SparkRegistry.register('unModifiers','constValue',ConstValue.create);
  }
  
}

class Repeater extends Component{

  static create() => new Repeater();
  
  Repeater(): super("Repeater"){
    this.meta('desc','a simple synchronous repeater component');
    this.loopPorts('in:in','out:out');
  }
  
}

class ConstValue extends Component{
  dynamic _value;
  
	static create() => new ConstValue();

	ConstValue(){
		this.meta('desc','takes a constant value from its option ports and always returns that value');
		
		this.port('static:option').tab((n){
		  this.setValue(n);
		});
    
		this.port('static:option').dataDrained.once((i){
		  	this.port('in:in').tap((k){
        		this.port('out:out').send(this._value);
      		});  
		});
		
	}
	
	void setValue(n){
	  if(Valids.exists(this._value)) return;
	  this._value = n;
	}
}

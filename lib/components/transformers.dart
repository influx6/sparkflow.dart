library sparkflow.transformers;

import 'package:hub/hub.dart';
import 'package:sparkflow/sparkflow.dart';

//this is a necessity and should be declared either as a static function in the class,to 
//add the necessary components to the SparkRegistery,unforunately there is no easy way
//to automatically run this once a library is imported;
class Transformers{
  
  static void registerComponents(){
    SparkRegistry.register("transformers", 'StringPrefixer', StringPrefixer.create);
    SparkRegistry.register("transformers", 'Prefixer', Prefixer.create);
    SparkRegistry.register("transformers", 'ApplyFunction', ApplyFunction.create);
  }
  
}


class ApplyFunction extends Component{
  Transformable handle;

  static create() => new ApplyFunction();
  
  ApplyFunction(){
    this.meta('desc','applies a function to every input stream from the inport');
    this.init();
  }
  
  void init(){
    var hin = this.port('in:in'), 
        hout = this.port('out:out'), 
        hop = this.port('static:option'), 
        herr = this.port('err:err');

    hop.tap((n){
      if(n is Function){
        if(Valids.exists(handle)) return this.handle.changeFn(n);
        this.handle = Transformable.create(n);
      }else herr.send(new Exception('$n is not a type of function!'));
    });

    hop.mixedDrained.once((n){
        hout.mixedTransformer.on(this.handle.out);
        hin.bindPort(hout);
    });
  }
  
}

class Prefixer extends Component{
  Transformable _combinator;
  
  static create(m,[n]) => new Prefixer(m,n);
 
  Prefixer(Function n,[String id]): super((id == null ? "Prefixer" : id)){
    this._combinator = Transformable.create(n);
    this.meta('desc','prefixing a value to a IP');
    this.makePort('in:internalBuffer');
    this.init();
  }

  void init(){
    var i = this.port('in:in');
    var o = this.port('out:out');
    var m = this.port('static:option');
    var buffer = this.port('in:internalBuffer');
    
    m.tap((h){
      this._combinator.change(h);
    });
    
    buffer.mixedTransformer.on((k){
      return this._combinator.out(k);
    });
    
    m.mixedDrained.once((n){
      i.bindPort(buffer);
      buffer.bindPort(o);
    });
    
  }

}

class StringPrefixer extends Prefixer{

  static create() => new StringPrefixer();

  StringPrefixer() : super((n,k){ 
    var pre = n.data + k.data;
    return pre;
  },"StringPrefixer");
  
}



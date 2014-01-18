library sparkflow.components;

import 'package:hub/hub.dart';
import 'package:sparkflow/sparkflow.dart';

class Repeater extends Component{

  static create() => new Repeater();
  
  Repeater(): super("Repeater"){
    this.meta('desc','a simple synchronous repeater component');
    this.loopPorts('in','out');
  }
  
}

class Prefixer extends Component{
  Transformable _combinator;
  
  static create(m,[n]) => new Prefixer(m,n);
 
  Prefixer(Function n,[String id]): super((id == null ? "Prefixer" : id)){
    this._combinator = Transformable.create(n);
    this.meta('desc','prefixing a value to a IP');
    this.makePort('internalBuffer');
    this.init();
  }

  void init(){
    var i = this.port('in');
    var o = this.port('out');
    var m = this.port('option');
    var buffer = this.port('internalBuffer');

    m.tap((h){
      this._combinator.change(h);
    });
    
    buffer.dataTransformer.on((k){
      return this._combinator.out(k);
    });
    
    m.dataDrained.once((n){
      i.bindPort(buffer);
      buffer.bindPort(o);
    });
    
  }

}

class StringPrefixer extends Prefixer{

  static create() => new StringPrefixer();

  StringPrefixer() : super((n,k){ return n+k; },"StringPrefixer");
  
}
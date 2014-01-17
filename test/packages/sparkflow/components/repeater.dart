library sparkflow.utils;

import 'package:sparkflow/sparkflow.dart';

class Repeater extends Component{

  static create() => new Repeater();
  
  Repeater(): super("Repeater"){
    this.meta('desc','a simple synchronous repeater component');
    this.loopPorts('in','out');
  }
  
  
}

class Prefixer extends Component{
  static StringBuffer combinator = new StringBuffer();
  
  static create() => new Prefixer();

  Prefixer(): super("Prefixer"){
    this.meta('desc','prefixing a value to a IP');
    this.init();
  }

  void init(){
    var i = this.port('in');
    var o = this.port('out');
    var m = this.port('option');
    
    
  }

}


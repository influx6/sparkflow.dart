library flow.utils;

import 'package:flow/flow.dart';

class Repeater extends Component{

  static create([String id]) => new Repeater(id);
  
  Repeater([String id]): super((id != null ? id : "Repeater")){
    this.meta.update('desc','a simple synchronous repeater component');
    this.makePort('in');
    this.makePort('out');
    this.loopPorts('in','out');
  }
  
  
}


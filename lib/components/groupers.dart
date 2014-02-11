library sparkflow.groupers;

import 'package:hub/hub.dart';
import 'package:sparkflow/sparkflow.dart';


class Groupers{
  
  static void registerComponents(){
    SparkRegistry.register("transfomers", 'GroupPackets', GroupPackets.create);
  }
  
}

class GroupPackets extends Component{

  static create([i]) => new GroupPackets(i);
  
  GroupPackets([String id]) : super(Hub.switchUnless(id,'GroupPackets')){

  }
  
}
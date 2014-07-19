library flow.specs;

import 'package:sparkflow/sparkflow.dart';
import 'package:ds/ds.dart';

void main(){
  var h = Packet.create();
  h.init('test','aliby',null,null);

  h.addBranch('throttle');

  h.branch('throttle')..data('song')..data('is')..data('so')..data('cool');

  var list = (h.branch('throttle').disjoin());

  assert(list is ds.dsList);


}

library flow.specs;

import 'package:sparkflow/sparkflow.dart';

void main(){
    
    var com = Component.create();
    var man = PortManager.create(com);

    man.createSpace('space');
    man.createSpace('earth');

    var spacein = man.createInport('space:in');
    var earthin = man.createInport('earth:in');

    assert(man.toMeta is Map);

    man.resumePort('space:in');
    assert(spacein.isConnected);
    man.pauseAll(); 
    assert(!spacein.isConnected);
    assert(!earthin.isConnected);
    man.resumePort('space');
    assert(spacein.isConnected);
    assert(!earthin.isConnected);

}

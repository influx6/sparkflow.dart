library flow.specs;

import 'package:flow/flow.dart';
import 'package:ds/ds.dart';

void main(){
  
  var network = Network.create('basics');

  var rep1 = Component.create('loopback');
  rep1.renamePort('in','suck');
  rep1.renamePort('out','spill');
  
  var rep2 = Component.create('slug');
  rep2.renamePort('in','en');

  var cosmo = Component.create('super');
  cosmo.makePort('en');
  cosmo.makePort('out');

  network.add(rep1,rep1.id);
  network.add(rep2,rep2.id);
  network.add(cosmo,cosmo.id);
  
  network.get('super').then((_){
    print('i got $_');
  });
}

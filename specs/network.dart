library flow.specs;

import 'package:flow/flow.dart';
import 'package:ds/ds.dart';

void main(){
  
  var network = Network.create();

  var rep1 = Component.create();
  rep1.renamePort('in','suck');
  rep1.renamePort('out','spill');
  
  var rep2 = Component.create();
  rep2.renamePort('in','en');

  var cosmo = Component.create();
  cosmo.makePort('en');
  cosmo.makePort('out');

  network.add(rep1,'loopback');
  network.add(rep2,'basic');
  network.add(cosmo,'cosmo');
  
  network.get('super').then((_){
    print('i got $_');
  });
}

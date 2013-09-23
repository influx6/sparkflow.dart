library flow.specs;

import 'package:flow/flow.dart';
import 'package:flow/components/repeater.dart';

void main(){
  
  var rep1 = Repeater.create();
  rep1.renamePort('in','suck');
  rep1.renamePort('out','spill');
  
  var rep2 = Prefixer.create();
  rep2.renamePort('in','en');

  rep2.option.connect();
  rep2.option.send('slug::');

  var cosmo = Component.create();
  cosmo.makePort('en');
  cosmo.makePort('out');

  cosmo.addCosmo(rep1);
  cosmo.addCosmo(rep2);

  cosmo.en.attach(rep1.suck);
  rep1.spill.attach(rep2.en);
  rep2.out.attach(cosmo.out);
  
  cosmo.out.listen((_){
    print('cosmo received: $_');
  });
  
  
  cosmo.en.send(1);
  cosmo.en.send(2);
  cosmo.en.send('x');
  cosmo.en.beginGroup('<code>');
  cosmo.en.send(4);
  cosmo.en.endGroup('</code>');
  cosmo.en.send(1);
    
}


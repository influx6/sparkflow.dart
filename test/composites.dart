library flow.specs;

import 'package:sparkflow/sparkflow.dart';
import 'package:sparkflow/components/repeater.dart';

void main(){
  
  var rep1 = Repeater.create();
  rep1.renamePort('in','suck');
  rep1.renamePort('out','spill');
  
  var rep2 = StringPrefixer.create();
  rep2.renamePort('in','en');

  rep2.port('option').connect();
  rep2.port('option').send('slug::');

  var cosmo = Component.create();
  cosmo.makePort('en');
  cosmo.makePort('out');

  cosmo.addCosmo(rep1);
  cosmo.addCosmo(rep2);

  cosmo.port('en').attach(rep1.suck);
  rep1.port('spill').attach(rep2.en);
  rep2.port('out').attach(cosmo.out);
  
  cosmo.port('out').tap((_){
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


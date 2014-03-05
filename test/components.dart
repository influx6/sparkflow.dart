library flow.specs;

import 'package:sparkflow/sparkflow.dart';
import 'package:sparkflow/components/transformers.dart';
import 'package:sparkflow/components/unmodifiers.dart';

void main(){
  
  var repeater = Repeater.create();
  var prefixer = StringPrefixer.create();

  repeater.renamePort('in','suck');
  repeater.renamePort('out','spill');

  var feeder  = Port.create('feeder');
  var reader  = Port.create('writer');
  var feeder2  = Port.create('feeder');
  
  reader.tap('data',(n){ print('#log  => $n'); });
  
  feeder.bindPort(repeater.port('suck'));
  repeater.port('spill').bindPort(reader);
  
  
  feeder2.bindPort(prefixer.port('in'));
  prefixer.port('out').bindPort(reader);
  
  feeder.send('alex');
  feeder.send('i need salt!');
  feeder.beginGroup('<article>');
  feeder.send('1: road');
  feeder.endGroup('</article>');
  
  prefixer.port('option').send('number:');
  feeder2.send('1');
  feeder2.send('2');
  feeder2.send('4');

//  repeater.getPortClassList();
//  print(repeater.toMeta);
  var a = Component.createFrom(repeater.toMeta);
  
}


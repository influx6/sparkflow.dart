library flow.specs;

import 'package:flow/flow.dart';
import 'package:flow/components/repeater.dart';

void main(){
  
  var repeater = Repeater.create();
  repeater.renamePort('in','suck');
  repeater.renamePort('out','spill');

  var feeder  = Port.create('feeder');
  var reader  = Port.create('writer');
  
  reader.listen((n){ print('#log  => $n'); });

  feeder.attach(repeater.suck);
  repeater.spill.attach(reader);

  feeder.send('alex');
  feeder.send('i need salt!');
  feeder.beginGroup('<article>');
  feeder.send('1: road');
  feeder.endGroup('</article>');

}


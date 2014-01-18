library flow.specs;

import 'package:sparkflow/components/repeater.dart';

void main(){
  
  var prefixer = StringPrefixer.create();
  
  prefixer.port('out').tap((n){
    print('prexifing: $n');
  });
  
  prefixer.port('in').send('one');
  
  prefixer.port('option').send('tag::');
  
  prefixer.port('in').send('two');

  prefixer.port('in').send('three');

  prefixer.port('option').send('rat::');

  prefixer.port('in').send('four');

}
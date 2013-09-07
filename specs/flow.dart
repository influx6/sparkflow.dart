library flow.specs;

import 'package:flow/flow.dart';

void main(){
  
  var port = Port.create('in');
  var ip = IP.create('hull',{
    'NAME':'name','AGE':'age'
  },'1');

  var socket = Socket.create(port,port);
  socket.beginGroup('<article>');
  socket.send('1');
  socket.endGroup('</article>');
  socket.beginGroup('<article>');
  socket.send('3');
  socket.endGroup('</article>');
  socket.beginGroup('<article>');
  socket.send('4');
  socket.endGroup('</article>');

  socket.streams.listen((n){
    print('am getting: $n');
  });

  socket.send('2');
}

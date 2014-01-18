# SparkFlow
####Version: 0.0.1
####Description: 
	a flow-based component system in dart with a better expressive api

####Features
	- Component : Provides component level structure for this platform
	- Port: provides a stream approach for communication between components
	- Socket: The basic connection end-point between two ports
	- SocketStream: The backend of sockets that provides the streaming api
	- SparkFlow: a top level class that provides a simpler api for instantiating a network and adding components 

Example:

  Component: A simple combination of a repeater and string prefixer components, every components
  at creation has4 predefined ports (in,out,option and err),where each provides a stream input for the 
  component
  
    //repeaters take and give what they recieve
    var repeater = Repeater.create();
    //prefixer takes an input and prefix a value it receives from its option stream to the input value
    var prefixer = StringPrefixer.create();

    //you can rename ports names
    repeater.renamePort('in','suck');
    repeater.renamePort('out','spill');

    //basic creation of ports,used internally by components
    var feeder  = Port.create('feeder');
    var reader  = Port.create('writer');
    var feeder2  = Port.create('feeder');
  
    //usually ports are to be bounded to other ports but to peek into the stream
    //of a port,simply tap into it
    reader.tap((n){ print('#log  => $n'); });
  
    //standard method of binding/connecting to ports to each other
    feeder.bindPort(repeater.port('suck')); //connect feeder's to reader suck port
    repeater.port('spill').bindPort(reader); //connect repeater's spill port to reader
  
  
    feeder2.bindPort(prefixer.port('in'));
    prefixer.port('out').bindPort(reader);
  
    //send data to all connected ports of feeder
    feeder.send('alex');
    feeder.send('i need salt!');
    
    //In FBP,there is a notion of substreams,which can be anchored by specific tags
    // here the feeder is pushing a substream of article tag: 
    // <article>1: road</article>
    //begins the substream
    feeder.beginGroup('<article>');
    //data in the substream,can be called countless times to add data into the grouping
    feeder.send('1: road');
    //ends the substream
    feeder.endGroup('</article>');
  
    //without the option port recieving input the prefixer will buffer its streams,
    //that is,the option port serves as a means of parsing options to the component or port
    //like a value passed to a function call
    prefixer.port('option').send('number:');
    
    feeder2.send('1');
    feeder2.send('2');
    
    //this can be called over again to change the prefixed value
    prefixer.port('option').send('tag:');

    feeder2.send('4');
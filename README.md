# SparkFlow

####Description: 
	A flow-based component system in dart with for the development of applications following a
	better data and control flow approach with a visual approach to coding. Flow Based Programming is an old paradigm 
	giving new life and ease to the development and deployment of ready made applications that provides the flexibility
	and asynchronouse demands of todays systems. Developed by J. Paul Morrisson <www.jpaulmorrison.com>
	back in the hay days of computer evolution. Though not eager adopted due to the madness for the conventions 
	at the time,it still has proven it self most vital and has brough new life into how we think and developed.
	
	Other systems exists which bring this old approach back to where it should be,such as:
	- NoFlo <noflojs.org> (Javascript implementation of FBP taking the world by storm)
	- Goflow (Golang version of FBP)
	- Microflo <http://www.jonnor.com/2013/11/microflo-0-2-0-visual-arduino-programming/>
  - ... and so much more.
  
####Features
	- Component : Provides component level structure
	- Port: provides a stream approach for communication between components
	- Socket: The basic connection end-point between two ports
	- SocketStream: The backend of Socket that provides the streaming api
	- Network: a graph based system of organizing and connecting components to form a huge application,also used in components for composition
	- SparkFlow: a top level class that provides a simpler api for instantiating a network and adding components 

####Implemented
  - Component,Socket, Ports and Network system
  
####Todo:
  - Development of sets of core components (concat,prefixers,loopers,..etc)
  - Development of an intermediate dsl for easy creation of applications or adopt noflo fbp format
  - Development of core web components for rapid development of web applications (client-sided and server-sided)
  - Improvement of underline structure and integration with a UI(possible noflo-UI)
  - .. and so much more :)
  
####Example:

  Component: A simple combination of a repeater and string prefixer components, every components
  at creation has4 predefined ports (in,out,option and err),where each provides a stream input for the 
  component
  
    repeaters take and give what they receive
    var repeater = Repeater.create();

    prefixer takes an input and prefix a value it receives from its option stream to the input value
    var prefixer = StringPrefixer.create();

    you can rename ports names
    repeater.renamePort('in','suck');
    repeater.renamePort('out','spill');

    basic creation of ports,used internally by components
    var feeder  = Port.create('feeder');
    var reader  = Port.create('writer');
    var feeder2  = Port.create('feeder');
  
    usually ports are to be bounded to other ports but to peek into the stream of a port,simply tap into it
    reader.tap((n){ print('#log  => $n'); });
  
    standard method of binding/connecting to ports to each other
    feeder.bindPort(repeater.port('suck')); //connect feeder's to reader suck port
    repeater.port('spill').bindPort(reader); //connect repeater's spill port to reader
  
  
    feeder2.bindPort(prefixer.port('in'));
    prefixer.port('out').bindPort(reader);
  
    send data to all connected ports of feeder
    feeder.send('alex');
    feeder.send('i need salt!');
    
    In FBP,there is a notion of substreams,which can be anchored by specific tags
    here the feeder is pushing a substream of article tag: 
     <article>1: road </article>

    begins the substream
    feeder.beginGroup('<article>');

    data in the substream,can be called countless times to add data into the grouping
    feeder.send('1: road');

    ends the substream
    feeder.endGroup('</article>');
  
    without the option port recieving input the prefixer will buffer its streams,
    that is,the option port serves as a means of parsing options to the component or port
    like a value passed to a function call
    prefixer.port('option').send('number:');
    
    feeder2.send('1');
    feeder2.send('2');
    
    this can be called over again to change the prefixed value
    prefixer.port('option').send('tag:');

    feeder2.send('4');

  Network: Its the core of all fbp application,managing the connections of ports and component instances registered to it and internally provides the subgraph functionality for all components, an example is as below, but please not that instead of adding instances directly,its preferable to register
  a function that generates the instance with SparkRegistry.

    Example from /test/network.dart
    
      library flow.specs;

      import 'package:sparkflow/sparkflow.dart';

      void main(){
        
        var network = Network.create('example');

        network.networkStream.pause();
        
        var loop = Component.create('loop');
        loop.renamePort('in','suck');
        loop.renamePort('out','spill');
        loop.loopPorts('suck','spill');
        
        var costa = Component.create('costa');

        var cosmo = Component.create('cosmo');

        network.addComponentInstance(loop,'loopback');
        network.addComponentInstance(costa,'costa');
        network.addComponentInstance(cosmo,'cosmo');
        
        network.filter('cosmo').then((_){
          assert(_.data.UID == cosmo.UID);
        });
        
        //order goes component who wants to connect to component port with port
        network.connect('costa','loopback','in','out');

        network.freeze();
        //listen to info streams for update
        network.networkStream.on((n){
          print('#Updates: \n $n \n');
        });

        network.boot();
      }


  SparkFlow: the top level object in Sparkflow, covers up alot of the nitty gritty and over-verbose calls for network and component configuration,it also
  ensures and enforces the use of SparkRegistry as a global component pool which allows proper grouping and generation of component instances and genrealy serves for smooth operation,an example is as below:

      Example from the file: test/sparkflow.dart
      
      library sparkflow.protocol;


      import 'package:sparkflow/sparkflow.dart';
      import 'package:sparkflow/components/unmodifiers.dart';
      import 'package:sparkflow/components/transformers.dart';

      void main(){
        
        assert(SparkRegistry != null);

      
        Due to the current state of dynamic loading of coding ,beyond the use of defferedlibrary
        or using spawnURL and then transporting the loading objects from the spawned isolate (does not work in js),
        a simplified method was choosen where a library defines its components and provides a static method,where
        it registers them up into the SparkRegistry which is a global class with static objects and functions, and is used
        by the Sparkflow class to grab the components,so its a very important,do not miss it type of thing.

        I would prefer a simplified,automatically register the functions,but unlike JS we cant just run a function off in a 
        class file,so a alternate method was needed,if you wish to write your own components ensure to provide something similar
        to this to register up the components for global access by SparkFlow.
        Note: there is no way around it!

          Example: #from the /lib/components/unmodifiers.dart

          library sparkflow.unmodifiers;

          import 'package:hub/hub.dart';
          import 'package:sparkflow/sparkflow.dart';

          Feel free to defined yours as you prefer,either as this,or a static method in the Repeater class (a better option if its just one component),
          or as a global static function,just ensure to note it in the README.md or any viable documentation,with this when we load this library like below:
             
          class UnModifiers{

            static void registerComponents(){
              SparkRegistry.register("unModifiers", 'Repeater', Repeater.create);
            }

          }

          class Repeater extends Component{

            static create() => new Repeater();

            Repeater(): super("Repeater"){
              this.meta('desc','a simple synchronous repeater component');
              this.loopPorts('in','out');
            }

          }
        
        
          this is a necessity and should be declared either as a static function in the class,to 
          add the necessary components to the SparkRegistery,unforunately there is no easy way
          to automatically run this once a library is imported;
         
          Component.registerComponents();
          UnModifiers.registerComponents();
          Transformers.registerComponents();
          
          var sf = SparkFlow.create("example.basic", "standard sf object to use");
            
          SparkFlow.use: Arguements
           1. path of the component in the registry(name of group / name of component)
           2. alias for component 
           3. List of arguments
           4. Map for named arguments
           5. Function for extra duties
          note: now all components automatically get their options port attached to the IIPSocket(no-overrides)
            
          sf..use('transformers/StringPrefixer','stringer',null,null,(m){
            m.port('in').tap((n){ print('stringer-in:$n');});
            m.port('out').tap((n){ print('stringer-out:$n');});
          })
          ..use('components/component','cosmo',null,null,(m){
            m.port('in').tap((n){ print('cosmo-in:$n');});
            m.port('out').tap((n){ print('cosmo-out:$n');});
          })
          ..use('unModifiers/Repeater','repeater',null,null,(m){
            m.port('in').tap((n){ print('repeater-in:$n');});
            m.port('out').tap((n){ print('repeater-out:$n');});
          });
          
          repeaters-out will feed stringers in
          sf.ensureBinding('stringer','in','repeater','out');

          cosmo out will feed repeaters in
          sf.ensureBinding('repeater','in','cosmo','out');

          cosmo in will feed cosmo out
          sf.ensureBinding('cosmo','out','cosmo','in');

          network(*) in will feed cosmo's in
          sf.ensureBinding('cosmo','in','*','in');

          cosmo out will feed network out
          sf.ensureBinding('*','out','stringer','out');


          sf.network.connectionStream.on((e){
             print('connection#${e}');
          }); 

          sf.onAlive((net){
            print('booting connections!');
          });

          sf.onDead((net){
            print('shutdowing!');
          });

          sf.boot().then((_){
                
            _.port('out').tap((n){
                print('network spouting: $n');
            });

            _.addInitial('stringer','network::');

            _.port('in').send('sanction'); 

          });
          
        
      }

    
######ThanksGiving    
I just wish to show great gratitude to God for helping to get this code to this level,being a long time,experimenting and moving back and forth between JavaScript and Dart towards reaching my goal of an awesome framework or approach to develop consistent web applications,though the road is still long but i can finally say first milestone has been reached and it wont have been possible without God's merciful hands. Let his name be praised.
Woot!
---------------------------------------------------------------------------------------------------
SparkFlow.dart (my fbp implementation for dartlang)
http://github.com/influx6/sparkflow.dart

Flow based development api finally reach milestone one for dart and now what remains is to bring it up to shape with large sets of components and either a ui or integrate with noflo-ui. Hope the dart community joins in to bring Fbp to dart as an alternative approach to application development.

PS: Gratitude to Henry Bergius (http://bergie.iki.fi/) for the introduction to the approach while i was searching for an approach that really made sense! 
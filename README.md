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
  - Development of an intermediate script language for easy creation of applications or adopt noflo fbp format
  - Development of core web components for rapid development of web applications (client-sided and server-sided)
  - Improvement of underline structure and integration with a UI(possible noflo-UI)
  - .. and so much more :)
  
####Example:

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


  Network: The network is the basis of components management and its also used for composition in components,every component has a network ready to be used,
  due to the nature of dart and futures being used,the connec and disconnect calls are asynchronous,hence the need to first write out all connections to be made
  and use a wait future to begin initiating the network when all connections begin,else the data will be sent before connections are made,an eg.


    import 'package:sparkflow/sparkflow.dart';
    import 'package:sparkflow/components/repeater.dart';

    void main(){
      
      var rep1 = Repeater.create();
      var rep2 = StringPrefixer.create();
      var cosmo = Component.create('cosmo');

      //lets loop cosmo in port to its outport,a basic repeater 
      cosmo.loopPorts('in','out');

      var network = Network.create("testBed");
      
      network.add(rep1,'repeater');
        
      network.add(rep2,'prefixer',(meta){
        //get access to the component ,iipsocket already attached to components options port (no-overrides)
      });

      network.add(cosmo,'cosmo');

      /*order goes:
        1: component who wants to connect
        2: port name of component who wants to connect
        3: component to be connected to
        4: port name of component to be connected to
      Optional:
        5: a tag name to be giving the socket,incase of selective message eg. send('data','1' or 'goba');
        6: bool value to dictate it uses breadthfirst search technique instead of the default depthfirst
      */
      //prefixer wants to connect its 'in' port to repeaters 'out'
      //repeater wants to connect its 'out' port to cosmo 'in' port;;
      //needed due to the nature of network connections using futures
      network
      .connect('prefixer','in','repeater','out')
      .connect('repeater','in','cosmo','out',null,true).boot().then((_){
        print(_);
        assert(_ == network);
        //its not always necessary for a networks in and outports to be connect,but there are cases eg composite components
        //where data must be fed into the network for its components to process
            
        //we will connect networks in port (nin) to cosmo 'in' port
        network.nin.bindPort(cosmo.port('in'));
        // tap into networks out port 'nout' to see what comes out

        network.nout.tap((n){
          print('network spouting: $n');
        });

        //only the prefixer component requires data feed into it before its operational,so add a IIP data for it,
        //you can always add another iip data to change the prefix;
        network.addInitial('prefixer','network::');


    //    cosmo.port('in').tap((n){
    //      print('cosmo in: $n');
    //    });
    //
    //    cosmo.port('out').tap((n){
    //      print('cosmo out: $n');
    //    });
    //
    //    rep1.port('in').tap((n){
    //      print('repeater in: $n');
    //    });
    //
    //    rep1.port('out').tap((n){
    //      print('repeater out: $n');
    //    });
    //
    //    rep2.port('in').tap((n){
    //      print('prefixer in: $n');
    //    });
    //
    //    rep2.port('out').tap((n){
    //      print('prefixer out: $n');
    //    });


        rep2.port('out').bindPort(network.nout);

        network.nin.send('sanction'); 
        
        return _;
      }).catchError((e){
        throw e;
      });
      
      network.whenAlive.then((_){
        network.freeze();
        
        network.whenFrozen.then((_){
          network.nin.send('frozen!');
          network.boot();
        });
        
      });

    }

  
  SparkFlow: the top level object in Sparkflow, covers up alot of the nitty gritty and over-verbose calls for network and component configuration,it also
  ensures and enforces abit more conditions for smooth operation,an example is as below:

      Example from the file: test/sparkflow.dart
      
      library sparkflow.protocol;


      import 'package:sparkflow/sparkflow.dart';
      import 'package:sparkflow/components/unmodifiers.dart';
      import 'package:sparkflow/components/transformers.dart';

      void main(){
        
        assert(SparkRegistry != null);

        /*
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
              or as a global static function,just ensure to note it in the README.md or any viable documentation,with this when we load this library we simple
              call:
                UnModifiers.registerComponents();
              to add the sets of components to the global SparkRegistry and hence be able to address them in Sparkflow
                 
              class UnModifiers{

                static void registerComponents(){
                  SparkRegistry.register("unModifiers", 'Repeater', Repeater.create);
                  //or
                  SparkRegistry.register("unModifiers", 'Repeater', (){
                    return new Repeater();
                  });

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
        */ 

        Component.registerComponents();
        UnModifiers.registerComponents();
        Transformers.registerComponents();

        //or
        // this is to following DRY approach,so prepferable use the above method
        SparkRegistry.register('transformers','repeater',(){ return new Repeater(); });
        
        var sf = SparkFlow.create("example.basic", "standard sf object to use");
          
          //SparkFlow.use: Arguements
          // 1. path of the component in the registry(name of group / name of component)
          // 2. alias for component 
          // 3. List of arguments
          // 4. Map for named arguments
          // 5. Function for extra duties
          // note: now all components automatically get their options port attached to the IIPSocket(no-overrides)
          
        sf..use('transformers/StringPrefixer','stringer',null,null,(m){
      //    m.port('in').tap((n){ print('stringer-in:$n');});
      //    m.port('out').tap((n){ print('stringer-out:$n');});
        })
        ..use('components/component','cosmo',null,null,(m){
      //      m.port('in').tap((n){ print('cosmo-in:$n');});
      //      m.port('out').tap((n){ print('cosmo-out:$n');});
        })
        ..use('unModifiers/Repeater','repeater',null,null,(m){
      //      m.port('in').tap((n){ print('repeater-in:$n');});
      //      m.port('out').tap((n){ print('repeater-out:$n');});
        });
        
        //repeaters-out will feed stringers in
        sf.ensureBinding('stringer','in','repeater','out');
        //cosmo out will feed repeaters in
        sf.ensureBinding('repeater','in','cosmo','out');
        //cosmo in will feed cosmo out
        sf.ensureBinding('cosmo','out','cosmo','in');
        //network(*) in will feed cosmo's in
        sf.ensureBinding('cosmo','in','*','in');
        //cosmo out will feed network out
        sf.ensureBinding('*','out','stringer','out');


        sf.network.connectionStream.on((e){
      //    print('connection#${e}');
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
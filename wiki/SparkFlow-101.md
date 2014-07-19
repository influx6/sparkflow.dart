
# Sparkflow.dart Introduction
 Sparkflow is the fbp implementation for dartlang and contains a few set of rules as to how it works and this wiki is to help with that to ensure appropriate information. Sparkflow is generally built to be general purpose, that is its not geared towards any particular application by default,this is done to ensure all possible applications can be built with it in ease and application or rather specialization of its application is left to the developer and to the components they create with it. For now Sparkflow has no UI, am hoping to integrate it properly with the NoFlo UI but there are certain norms and things that don't generally map one to one from JS to dart and also as a personal challenge I do plan to build a native UI for Sparkflow,not as a competition to the already advance noflo ui and the comming FlowHub but as means of experimentation to see whats possible with a native UI and native backend with Sparkflow,these way we can take advantage of things dart is good at.


## Principle
 Sparkflow from the one set is made to be very simple,easy to get started with and easy to play around with, although there are certain pre-steps required to ensure easy and quick use of code but these are generally easy to move with and should not be a problem nor get in the way of fun.
All components and network object follow a basic port configuration,that is there exists a:

    in port group: to represent the sets of input ports

    out port group: to represent the sets of output ports

    err port group: to represent the sets of err ports

    static port group: to represent extra ports eg option ports that are needed.

Option ports are important though its left to the developer to use as they are an approach to providing initail information packets and they are the approach used in Sparkflow especially for Networks and Components and they exist within the **static port group**.



## Components


1. Sockets: the real core of the communication of component is the sockets and they exist for that purpose,they are single stream elements which use my custom library Streamable.dart(http://github.com/influx6/streamable.dart) and are easy to use and get with. Sockets basically provide no generally restrictions are easy to get started with it,as below. But one thing to note is unlike JS where we can do typeof checks ,its rather hard to perform such dynamically using is,is! and as in dart,so to fix these sockets come with a condition checker which functions can be added to during code time,to perform checks on the data(but might change to the packet object for flexibility) of the packet being sent through by calling the **Socket.forceCondition** function with a bool function that returns true or false, when packets are sent those conditions are checked and if any return false, the packet is discarded and not allowed to go through into the socket stream, also both data,beginGroup and endGroup have condition checkers for flexibility.Like standard socket implementation, it provides the general basic function calls in fbp,general list of important functions are:
   
     send: to send data packets through the socket stream

     beginGroup: to begin a packet grouping(substream) with a tag or value

     endGroup: to end a packet grouping(substream) with a tag or value

     bindSocket: binds another socket to the current socket (basically pipes data into the other socket)

     unbindSocket: detaches the bounded socket from the list of subscribers

     attachPort: attaches a port's socket using bindSocket underneath

     detachPort: detaches a port's socket

     setMax: to set maximum allowed packets in this socket stream

     flushPackets: to flush the packets within the socket( destroy them)

     metas: allows the addition or retrieval of meta data from the socket (id,name,fromPort,..etc)

     on: to attach a function into the socket stream

     off: to detach a function from the socket stream

     detachAll: removes all subscribers and functions from the socket stream

     resume: resumes the socket operations

     pause: pauses the socket operations

     close/end: closes the socket operations

   
    Basic Example:

`

        var toPort = Socket.create(),
            fromPort = Socket.create();
 
        toPort.bindSocket(fromPort);

        fromPort.on((n){
          print('#fromPort recieves: $n');
        });
  
        toPort.forceCondition((n){ return (n is String); });

        toPort.send('think');
        toPort.send('straight');
        toPort.send('my');
  
        toPort.send(1);

        toPort.beginGroup('<people>');
        toPort.send('sunday');
        toPort.send('!');
        toPort.endGroup('</people>');
  

        toPort.unbindSocket(fromPort);

        toPort.send('not-recieved!');

    `

2. Ports: this is the high level channel of communication seen by most developers and generally the overlord of communication for components within fbp and sparkflow lacks nothing with them, unlike the current Port API in Noflo, in dart things work differently hence a few operations dont generally map one to one from JS to dart. But the API for Ports in sparkflow is pretty easy to get down with and Ports generally extend Sockets with extra functionality. Ports used in components are group mapped, i.e they are grouped by the class and in Sparkflow its not restricted to the In,Out,Error groups, generally you can create different groups as the symantic of an inport,outport are not intensely defined and enforced. Below is an example of the Port API:
  
  Basic Port Example:

        `

          //Arguments:
            1. name or id of the port

            2. group or class of the port (not strigently defined)

            3. meta data for these port,can contain extra information that may also modify the behaviour of the port for example the data type information that the port may allow or condition functions for validation of packets,but this is still under consideration


          var toPort = Port.create('out','out',{
              'name':'toPort',
          });
          var fromPort = Port.create('in','in',{
              'name':'fromPort',
          });
          
          //toPort.forceCondition((n){ return (n is String); });

          // bind the toPort into the fromport to receive packets
          fromPort.bindPort(toPort);
          
          // tap into the port stream
          toPort.tap((n){
             print('#toPort recieves: $n');
          });
          
          // send data packet
          fromPort.send('love');

          //send begingroup packet
          fromPort.beginGroup('<note>');

          // send data packet
          fromPort.send('i need a drink!');

          // send endgroup packet
          fromPort.endGroup('</note>');

          // since the port and socket API depends on the streamable library,it gets for free a transfomer(its a mutator in truth) which can be used to modify the packet as it arrives into the stream 
          fromPort.mixedTransformer.on((n){
            n.data = n.data+"::";
            return n;
          });
          
          fromPort.send('someone');
          
          //Ports when bounded get a tag name either added by the binder or automatically assigned by the port internals,these allows addressing packets to specific subscribers of a port without sending the packet to all, general packet transformations apply to the packet also.
          fromPort.send('think','1');

          //clear out the transformer
          fromPort.mixedTransformer.freeListeners();
          
          // send more data packet
          fromPort.send('straight');
          fromPort.send('my');
          fromPort.send('people');
  
          //unsubscribe/unbind the toport from the fromport
          fromPort.unbindPort(toPort);
          
          //send the data packet but it gets buffered unless the port is set to flush packets or if a maxmimum packet gap is set but if there is a subscriber be it a port or a function the packet gets sent off else held in till there exist a subscribing port or funtion
          fromPort.send('!');

        `
  
3. Component: Components are the real deal,the concrete elements that are generally interacted with,the encapsulation block of composable unit level operations that provide the key blocks in FBP, and they are no less easy and straight up to use. The Sparkflow Component API comes with default set of port group or class and set of defaultly named ports which can be easily removed but most importantly is how components get registered and available for use, unlike in JS where Objects exists and can easily be introspected for values(eg meta data),dart is different and hence until instantiation, component meta data do not exists nor are available for probing,and this is not going to change as it would be un-necessary to always include a static meta attribute to all code especially when change may occur in configuration through the UI, also there exist the need for composition of components to provide extra functionality and in Sparkflow there exist no unique element for these as all Components come with an internal Network object which is instantiated when the **enableSubnet** or **useSubnet** is called and is started and stopped with the component,these contains the composite components that make up these component and through the standard network ports and special ports communicate, generally Composite components are seen as shells for networks and only just pipe in their ports into their internal network object where the real work takes place. Components provide a few set of core functions that provide the necessary functionality which include:

    boot: to start up the  component and the internal network if enabled/

    freeze: pauses the packet streams of the component ports and internal network

    shutdown: closes the component,its internal network,flushes all packets in the streams,basicly turns a component un-operation until boot up.


    
  Components come with a form of port grouping mechanism which allows the creation of ports sets according to their classes,as in the in,out,err convention,as stated these convention are not enforced as a Port is a port and can either be for input and output,but to ensure compatibility with noflo's port API groupings are used but the names for groupings can be anything desired but generally the in,out,err and static grouping is all that is needed.Generally port names are written in Group:ID format and is the general format for accessing a specific port in a component or in a network,so generally a group space is created and then either getting access to the PortManager for that component or using the component's **makePort** to create ports within that group as below:

    Internal PortGrouping API Example:

    `


      var com = Component.create();

      //internal portmanager used for all components
      var man = PortManager.create(com);
      
      //sets of port classes eg in,out,err,static..etc
      man.createSpace('space');
      man.createSpace('earth');
      
      // ports created using the class:id format where each gets added to its respective grouping/class
      var spacein = man.createPort('space:in');
      var earthin = man.createPort('earth:in');

      assert(man.toMeta is Map);
      
      //to resume a port through its portmanager without getting the port directly
      man.resumePort('space:in');
      assert(spacein.isConnected);
      
      //pause all port groups and their respective ports
      man.pauseAll(); 

      assert(!spacein.isConnected);
      assert(!earthin.isConnected);

      man.resumePort('space');

      assert(spacein.isConnected);
      assert(!earthin.isConnected);

    `

  Creation of Components is pretty easy and simple and specific defaults have been added,and little explanation is need for these,and a simple example is as below:

    `

       class ExampleComponent extends Component{
            
            static create() => new ExampleComponent();
            ExampleComponent(): super("custom name for component"){
                
                this.removeAllPorts();
                this.createSpace('retro');

                this.makePort('in:word');
                this.makePort('retro:count');
            }
       }
    `

  Use of components is a simple operation with just one specific and important rule to follow,unlike Noflo,components are registerd into a component registry and this is very important and is the standard means of getting and generating components and should not be missed. Because the registery provide a secure and standard means of grouping components and generating them,it is the generally means of instanciating or generating components,although its not enforced,its heavily advice to use it as in dart we dont get the joy of automatically running function calls within source files without a main function.Generally how you register is up to you but as standard components written come with a class named exactly the same with a static method called **registerComponents** and these exists in the default component class in sparkflow.This registry is called **SparkRegistry** and provides the necessary functions as stated below to registery and generate a specific component,when a component is registery,the component grouping is change and set to the groups it is added to in the registry,this allows us to generate the list of loaded components in the UI.

  
     Component Registrying Example:
        
    `

        Class Example{
            
            static registerComponents(){
                //call the default register function to get the default component into the registry
                Component.registerComponents();
                
                //Arguments:
                  1. name of component group
                  2. name of component
                  3. function that returns a new instance of the component
                SparkRegistry.register('example-class','example',ExampleComponent.create);
            }

        }
        
    `

   Use of SparkRegistry Example:(Example from the Spark_template library)
   
    Note: the groupname and name of component registered in the registry are accessed by using the groupname/componentname format as below.

    `


        import 'package:spark_templates/templates.dart';

        void main(){
           
           //adds the components from this library to the registry
          Templates.registerComponents();
            
          //SparkRegistry.generate takes the groupname/componentname for a component,check if it exists and runs the generation function passed in,also it can take two arguments,a list for positional arguments and a map for mapped arguments incase the component needs such.
          var stringer = SparkRegistry.generate('templates/StringTemplate');

          stringer.port('static:option').send('i love #name!');
          stringer.port('in:regexp').send('#name');
          stringer.port('out:res').tap(print);
          stringer.port('in:data').send('evelyn');

          var meta = SparkRegistry.generate('templates/metatemplate');
          meta.port('out:res').tap(print);
          meta.port('in:tmpl').send('socratic #name are #state');
          meta.port('in:data').send({'name':'scolars','state':'dead'});
          
          var loop = SparkRegistry.generate('templates/looptemplate');
          loop.port('out:res').tap(print);
          loop.port('in:tmpl').send('#index day of love');
          loop.port('in:data').send(6);

          var collect = SparkRegistry.generate('templates/collectiontemplate');
          collect.port('out:res').tap(print);
          collect.port('in:tmpl').send('#key day of love #value');
          collect.port('in:data').send({'state':'blue','country':'books'});

        }
    `

3. Network: This is the core means of management of components and the real connection strategy and underneath uses a graph for both management and transversal of components as is standard. It comes with specific and standard ports that never change and uses the SparkRegistry for the addition of components into the graph,as a means of flexibilty provides depthfirst and breadthfirst transversal,filtering functions but default is set to depthfirst  and also provides means of ensuring that connections persist between bootup and shutdown of network. Underneath it all the network API is a future based API,generall operations return futures and allow easier management of these states.General functions provided by the network api:

      boot: starts up the network

      freeze: pauses the network

      shutdown: stops and closes the network

      filter: to filter and get a component within the graph by id

      add: to add a component into the graph with a unique id (uses sparkregistry)

      remove: to remove a component from the graph with a unique id

      addComponentInstance: to add a component instance manually without using sparkregistry into the graph

      ensureBinding/ensureUnbinding: provides the means to persist connections of component between bootup and shutdown

      looseBinding/looseUnbinding: provides the standard connection directive but they dont persist after a shutdown.

    Within network API lies sets of standard streams which are used by for notification of events,since these are streams when they have listeners they propagate their packets,to ensure the information persist,it would be wise to attach some for of storage eg file or log as needed,these streams include:

      networkStream: all network related operations are sent here

      connectionStream: connection details are sent in here

      iipStream: contains information relating to initial information packets

      errorStream: all errors occuring in the network api

      componentStream: contains information on added and removed,booted and shutdown components.

**Note**: when using network api it would be better to use the ensurebinding/ensureunbinding or loosebinding/looseunbinding than using connect and disconnect as they provide a simpler and more functional approach to making connections.

    Example of Network API:

      `


        var network = Network.create('example');

        network.networkStream.pause();
        
        var loop = Component.create('loop');
        loop.loopPorts('in:in','out:out');
        
        var costa = Component.create('costa');

        var cosmo = Component.create('cosmo');

        network.addComponentInstance(loop,'loopback');
        network.addComponentInstance(costa,'costa');
        network.addComponentInstance(cosmo,'cosmo');
        
        network.filter('cosmo').then((_){
          assert(_.data.UID == cosmo.UID);
        });
        
        //order goes 

            1. component who wants to connect

            2. component to be connected to

            3. port of component who wants to connect

            4. port of component to be connected to

        network.connect('costa','loopback','in:in','out:out');

        network.freeze();
        //listen to info streams for update
        network.networkStream.on((n){
          print('#Updates: \n $n \n');
        });

        network.connectionStream.on((n){
          print('#Connections: \n $n \n');
        });

        network.iipStream.on((n){
          print('#iipStreams: \n $n \n');
        });

        network.errorStream.on((n){
          print('#errorStream: \n $n \n');
        });

        network.componentStream.on((n){
          print('#componentStream: \n $n \n');
        });

        network.boot();

      `

4. Sparkflow: This is the general encapsulation of all these into a single body to allow easy instantiation and reduce the need to create each parts  manaually, it contains a network where all components would be added and simple wrapps around the network object with basic management functionality. When desiring to either create a network or create a sparkflow instance,this is the object to use,makes the API cleaner and better.


  Example of Sparkflow Class:

  `


      var sf = SparkFlow.create("example.basic", "standard sf object to use");
        
        //SparkFlow.use: Arguements
        // 1. path of the component in the registry(name of group / name of component)
        // 2. alias for component 
        // 3. List of arguments
        // 4. Map for named arguments
        // 5. Function for extra duties
        // note: now all components automatically get their options port attached to the IIPSocket(no-overrides)
        
      sf..use('transformers/StringPrefixer','stringer')
      ..use('components/component','cosmo',null,null,(m){
          m.port('in:in').tap((n){ print('cosmo-in:$n');});
          m.port('out:out').tap((n){ print('cosmo-out:$n');});
      })
      ..use('unModifiers/Repeater','repeater');
      
      //repeaters-out will feed stringers in
      sf.ensureBinding('stringer','in:in','repeater','out:out');
      //cosmo out will feed repeaters in
      sf.ensureBinding('repeater','in:in','cosmo','out:out');
      //cosmo in will feed cosmo out
        sf.ensureBinding('cosmo','out:out','cosmo','in:in');
      //network(*) in will feed cosmo's in
      sf.ensureBinding('cosmo','in:in','*','in:in');
      //cosmo out will feed network out
      sf.ensureBinding('*','out:out','stringer','out:out');


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
            
        _.port('out:out').tap((n){
            print('network spouting: $n');
        });

        _.addInitial('stringer','network::');

        _.port('in:in').send('sanction'); 

      });
      

  `

More Examples:
  
  from test/composites.dart file:

  `




      library flow.specs;

      import 'package:sparkflow/sparkflow.dart';
      import 'package:sparkflow/components/transformers.dart';
      import 'package:sparkflow/components/unmodifiers.dart';

      void main(){
        
        var rep1 = Repeater.create();
        var rep2 = StringPrefixer.create();
        var cosmo = Component.create('cosmo');

        //lets loop cosmo in port to its outport,a basic repeater 
        cosmo.loopPorts('in:in','out:out');

        var network = Network.create("testBed");
        
        network.addComponentInstance(rep1,'repeater',(meta){
          //print('internal initial socket: ${meta.toString().split(',').join('\n')}');
        });
          
        network.addComponentInstance(rep2,'prefixer',(meta){
          //print('internal initial socket: ${meta.toString().split(',').join('\n')}');

          //attach the IIP to the component's option port
          //meta.socket.attachPort(meta.component.port('option'));
        });

        network.addComponentInstance(cosmo,'cosmo',(meta){
          //print('internal initial socket: ${meta.toString().split(',').join('\n')}');
        });

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
        .connect('prefixer','in:in','repeater','out:out')
        .connect('repeater','in:in','cosmo','out:out',null,true).boot().then((_){
          assert(_ == network);
          //its not always necessary for a networks in and out to be connect,but there are cases eg composite components
          //where data must be fed into the network for its components to process
              
          //we will connect networks in port (nin) to cosmo 'in' port
          network.nin.bindPort(cosmo.port('in:in'));
          // tap into networks out port 'nout' to see what comes out

          network.nout.tap((n){
            print('network spouting: $n');
          });

          //only the prefixer component requires data feed into it before its operational,so add a IIP data for it,
          //you can always add another iip data to change the prefix;
          network.addInitial('prefixer','network::');


      //	  cosmo.port('in').tap((n){
      //	  	print('cosmo in: $n');
      //	  });
      //
      //	  cosmo.port('out').tap((n){
      //	  	print('cosmo out: $n');
      //	  });
      //
      //	  rep1.port('in').tap((n){
      //	  	print('repeater in: $n');
      //	  });
      //
      //	  rep1.port('out').tap((n){
      //	  	print('repeater out: $n');
      //	  });
      //
      //	  rep2.port('in').tap((n){
      //	  	print('prefixer in: $n');
      //	  });
      //
      //	  rep2.port('out').tap((n){
      //	  	print('prefixer out: $n');
      //	  });


          rep2.port('out:out').bindPort(network.nout);

          network.nin.send('sanction'); 
          
          return _;
        }).catchError((e){
          throw e;
        });
        
        network.whenAlive.then((_){
          network.freeze();
          
          network.addInitial('prefixer','pre::');
         
          network.whenFrozen.then((_){
            network.nin.send('frozen!');
            network.boot();
            
            network.networkStream.on((m){
              print('update: \n $m \n');
            });
          });
          

        });

      //  this fires first and the other of data changes
      //  network.freeze();
      //  
      //  
      //  network.addInitial('prefixer','pre::');
      //  
      //  network.whenFrozen.then((_){
      //    print('isFrozen!');
      //    network.nin.send('frozen!');
      //    network.boot();
      //    
      //    network.infoStream.tap((m){
      //      print('update: \n $m \n');
      //    });
      //  });
        
      }

  `

  from test/prefixer.dart file:

  `



      library flow.specs;

      import 'package:sparkflow/components/transformers.dart';

      void main(){
        
        var prefixer = StringPrefixer.create();
        
        prefixer.port('out:out').tap((n){
          print('prexifing: $n');
        });
        
        prefixer.port('in:in').send('one');
        
        prefixer.port('static:option').send('tag::');
        
        prefixer.port('in:in').send('two');

        prefixer.port('in:in').send('three');

        prefixer.port('static:option').send('rat::');

        prefixer.port('in:in').send('four');

      }

  `

  from test/components.dart file:

    `


    import 'package:sparkflow/sparkflow.dart';
    import 'package:sparkflow/components/transformers.dart';
    import 'package:sparkflow/components/unmodifiers.dart';

    void main(){
      
      var repeater = Repeater.create();
      var prefixer = StringPrefixer.create();

      var feeder = Port.create('feeder','in',{});
      var feeder2 = Port.create('feeder','in',{});
      var reader = Port.create('writer','out',{});
      
      reader.tap((n){ print('#log  => $n'); });
      
      feeder.bindPort(repeater.port('in:in'));
      repeater.port('out:out').bindPort(reader);
      
      
      feeder2.bindPort(prefixer.port('in:in'));
      prefixer.port('out:out').bindPort(reader);
      
      feeder.send('alex');
      feeder.send('i need salt!');
      feeder.beginGroup('<article>');
      feeder.send('1: road');
      feeder.endGroup('</article>');
      
      prefixer.port('static:option').send('number:');
      feeder2.send('1');
      feeder2.send('2');
      feeder2.send('4');
       
      
      /* print(repeater.toMeta); */
      var a = Component.createFrom(repeater.toMeta);
      /* print(a.toMeta); */
      
    }

    `

Note: The network,component and portmanager provide a **toMeta** function among a few others which distill the general information into a map form for use or transfer for regeneration,as in the example in the test/components.dart folder where as below:

    `

          /* print(repeater.toMeta); */
          var a = Component.createFrom(repeater.toMeta);
          /* print(a.toMeta); */

    `

  A new component is generated with the details from another component,these allows cloning components internal blueprint although underneath the operation may differ,although this can be easily fixed if an approach of dynamic processing functions are sent in as stream packets which then determine the operation of the component but as always this choice is left to the developer. But these provide a proper means of getting blueprint information on both components and network for reconstruction or other operations.

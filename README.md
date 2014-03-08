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
  - Development of sets of core components (concat,prefixers,loopers,..etc)
  
####Todo:
  - Development of an intermediate dsl for easy creation of applications or adopt noflo fbp format
  - Development of core web components for rapid development of web applications (client-sided and server-sided)
  - Improvement of underline structure and integration with a UI(possible noflo-UI)
  - .. and so much more :)
  

    
######ThanksGiving    
I just wish to show great gratitude to God for helping to get this code to this level,being a long time,experimenting and moving back and forth between JavaScript and Dart towards reaching my goal of an awesome framework or approach to develop consistent web applications,though the road is still long but i can finally say first milestone has been reached and it wont have been possible without God's merciful hands. Let his name be praised.
Woot!
---------------------------------------------------------------------------------------------------
SparkFlow.dart (my fbp implementation for dartlang)
http://github.com/influx6/sparkflow.dart

Flow based development api finally reach milestone one for dart and now what remains is to bring it up to shape with large sets of components and either a ui or integrate with noflo-ui. Hope the dart community joins in to bring Fbp to dart as an alternative approach to application development.

PS: Gratitude to Henry Bergius (http://bergie.iki.fi/) for the introduction to the approach while i was searching for an approach that really made sense! 

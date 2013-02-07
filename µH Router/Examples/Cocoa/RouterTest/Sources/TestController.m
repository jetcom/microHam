//
//  TestController.m
//  RouterTest
//
//  Created by Kok Chen on 5/25/06.


#import "TestController.h"
#include "KeyerTest.h"
#include "RouterCommands.h"
#include "RouterPort.h"


@implementation TestController

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		//  Set delegate for -applicationShouldTerminate here
		[ [ NSApplication sharedApplication ] setDelegate:self ] ;
		//  launch µH Router
		[ [ NSWorkspace sharedWorkspace ] launchApplication:[ NSString stringWithUTF8String:"µH Router" ] ] ;
	}
	return self ;
}

- (void)awakeFromNib
{
	int routerRd, routerWr, keyerRd, keyerWr ;
	char kid[21] ;
	
	//  open read/write ports to Router
	routerRd = open( "/tmp/microHamRouterRead", O_RDONLY ) ;
	routerWr = open( "/tmp/microHamRouterWrite", O_WRONLY ) ;
	
	digiKeyer = microKeyer = cwKeyer = nil ;
	
	getKeyerID( 1, routerRd, routerWr, kid ) ;
	printf( "KEYERID returned (%s)\n", kid ) ;

	
	if ( routerRd > 0 && routerWr > 0 ) {
	
		if ( kid[0] == 'M' ) {
			//  use keyerID if the first character is M
			obtainRouterPortsForName( &keyerRd, &keyerWr, kid, routerRd, routerWr ) ;
			if ( keyerRd > 0 && keyerWr > 0 ) {
				microKeyer = [ [ KeyerTest alloc ] initIntoTabView:[ tabView tabViewItemAtIndex:2 ] read:keyerRd write:keyerWr ] ;
			}
		}
		else {
			obtainRouterPorts( &keyerRd, &keyerWr, OPENMICROKEYER, routerRd, routerWr ) ;
			if ( keyerRd > 0 && keyerWr > 0 ) {
				microKeyer = [ [ KeyerTest alloc ] initIntoTabView:[ tabView tabViewItemAtIndex:0 ] read:keyerRd write:keyerWr ] ;
			}
		}
		
		obtainRouterPorts( &keyerRd, &keyerWr, OPENCWKEYER, routerRd, routerWr ) ;
		if ( keyerRd > 0 && keyerWr > 0 ) {
			cwKeyer = [ [ KeyerTest alloc ] initIntoTabView:[ tabView tabViewItemAtIndex:1 ] read:keyerRd write:keyerWr ] ;
		}

		if ( kid[0] == 'D' ) {
			//  use keyerID if the first character is D
			obtainRouterPortsForName( &keyerRd, &keyerWr, kid, routerRd, routerWr ) ;
			if ( keyerRd > 0 && keyerWr > 0 ) {
				digiKeyer = [ [ KeyerTest alloc ] initIntoTabView:[ tabView tabViewItemAtIndex:2 ] read:keyerRd write:keyerWr ] ;
			}
		}
		else {
			obtainRouterPorts( &keyerRd, &keyerWr, OPENDIGIKEYER, routerRd, routerWr ) ;
			if ( keyerRd > 0 && keyerWr > 0 ) {
				digiKeyer = [ [ KeyerTest alloc ] initIntoTabView:[ tabView tabViewItemAtIndex:2 ] read:keyerRd write:keyerWr ] ;
			}
		}
		close( routerRd ) ;						//  no longer need router read port
		close( routerWr ) ;						//  no longer need router write port
	}
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)sender
{
	//  ask keyers to close ports
	if ( microKeyer ) [ microKeyer release ] ;
	if ( cwKeyer ) [ cwKeyer release ] ;
	if ( digiKeyer ) [ digiKeyer release ] ;
	return NSTerminateNow ;
}


@end

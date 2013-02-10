//
//  RouterTest.m
//  µH Router
//
//  Created by Kok Chen on 5/26/06.

#import "RouterTest.h"
#include "RouterCommands.h"


@implementation RouterTest

//  For internal testing of the µH Router
//
//	The RouterTest, KeyerTest, RouterPort set (together with the RouterTest and KeyerTest nibs) also works in
//	a stand alone test program that talks to the µH Router.

	
- (id)initWithRouters:(Router**)routerList count:(int)count
{
	self = [ self init ] ;
	if ( self ) {
		router = routerList ;
		routers = count ;
		[ NSBundle loadNibNamed:@"RouterTest" owner:self ] ;
		window = [ tabView window ] ;
		[ window setDelegate:self ] ;	//  for window closure
	}
	return self ;
}

- (void)openTest
{
	int routerRd, routerWr, keyerRd, keyerWr ;

	//  open read/write ports to Router
	routerRd = open( "/tmp/microHamRouterRead", O_RDONLY ) ;
	routerWr = open( "/tmp/microHamRouterWrite", O_WRONLY ) ;
	
	digiKeyer = microKeyer = cwKeyer = nil ;
		
	if ( routerRd > 0 && routerWr > 0 ) {

		obtainRouterPorts( &keyerRd, &keyerWr, OPENMICROKEYER, routerRd, routerWr ) ;
		if ( keyerRd > 0 && keyerWr > 0 ) {
			microKeyer = [ [ KeyerTest alloc ] initIntoTabView:[ tabView tabViewItemAtIndex:0 ] read:keyerRd write:keyerWr ] ;
		}
		obtainRouterPorts( &keyerRd, &keyerWr, OPENCWKEYER, routerRd, routerWr ) ;
		if ( keyerRd > 0 && keyerWr > 0 ) {
			cwKeyer = [ [ KeyerTest alloc ] initIntoTabView:[ tabView tabViewItemAtIndex:1 ] read:keyerRd write:keyerWr ] ;
		}
		obtainRouterPorts( &keyerRd, &keyerWr, OPENDIGIKEYER, routerRd, routerWr ) ;
		if ( keyerRd > 0 && keyerWr > 0 ) {
			digiKeyer = [ [ KeyerTest alloc ] initIntoTabView:[ tabView tabViewItemAtIndex:2 ] read:keyerRd write:keyerWr ] ;
		}
		close( routerRd ) ;						//  no longer need router read port
		close( routerWr ) ;						//  no longer need router write port
	}
}

- (void)openPanel
{
	[ window center ] ;
	[ window orderFront:self ] ; 
	[ window makeKeyWindow ] ; 	
	
	[ self openTest ] ;
}

//  delegate to window close
- (BOOL)windowShouldClose:(id)sender
{
	//  close out the keyers when the test window closes
	if ( microKeyer ) {
		[ microKeyer stopPollingKeyer ] ;
		[ microKeyer release ] ;
		microKeyer = nil ;
	}
	if ( digiKeyer ) {
		[ digiKeyer stopPollingKeyer ] ;
		[ digiKeyer release ] ;
		digiKeyer = nil ;
	}
	if ( cwKeyer ) {
		[ cwKeyer stopPollingKeyer ] ;
		[ cwKeyer release ] ;
		cwKeyer = nil ;
	}
	return YES ;
}


@end

//
//  main.c
//  TestCarbonPipe
//
//  Created by Kok Chen on 5/5/06.

#include <Carbon/Carbon.h>
#include "RouterCommands.h"

static void obtainRouterPorts( int *readFileDescriptor, int *writeFileDescriptor, int type, int parentReadFileDescriptor, int parentWriteFileDescriptor ) ;

//  This example opens up the PTT and serial CW ports to the DIGI KEYER and executes the following sequence with 1 second in between
//		turns on the PTT
//		turns on CW
//		turns off PTT
//		turns off CW

int main( int argc, char *argv[] )
{
	int routerRd, routerWr, keyerRd, keyerWr, ptt, cw ;
	char request[2] ;
	
	//  open read/write ports to Router
	routerRd = open( "/tmp/microHamRouterRead", O_RDONLY ) ;
	routerWr = open( "/tmp/microHamRouterWrite", O_WRONLY ) ;
	
	if ( routerRd > 0 && routerWr > 0 ) {
	
		// request ports to talk to the digi keyer
		obtainRouterPorts( &keyerRd, &keyerWr, OPENDIGIKEYER, routerRd, routerWr ) ;
		
		close( routerRd ) ;						//  no longer need router read port
		close( routerWr ) ;						//  no longer need router write port
		
		if ( keyerRd > 0 && keyerWr > 0 ) {
		
			//  get ptt and cw write ports to the DIGI KEYER
			obtainRouterPorts( nil, &ptt, OPENPTT, keyerRd, keyerWr ) ;
			obtainRouterPorts( nil, &cw, OPENCW, keyerRd, keyerWr ) ;
						
			if ( ptt > 0 && cw > 0 ) {
				//  got both a PTT port and a CW port
				write( ptt, "1", 1 ) ;					//  key PTT
				sleep( 1 ) ;
				write( cw, "1", 1 ) ;					//  keydown CW
				sleep( 1 ) ;
				write( ptt, "0", 1 ) ;					//  unkey PTT
				sleep( 1 ) ;
				write( cw, "0", 1 ) ;					//  keyup CW
			}
			
			//  all done, now tell router to clean up ports that are opend to us
			request[0] = CLOSEKEYER ;
			write( keyerWr, request, 1 ) ;

			close( keyerRd ) ;						//  no longer need keyer port
			close( keyerWr ) ;						//  no longer need keyer port
		}
	}
	return 0 ;
}


//  Open a pair of ports to the parent ports for read and write to a given type of connection
//	if one of the result pointers is nil, no open is made to that file descriptor
//	return -1 in all non-nil file descriptors of cannot open connection

static void obtainRouterPorts( int *readFileDescriptor, int *writeFileDescriptor, int type, int parentReadFileDescriptor, int parentWriteFileDescriptor )
{
	char path[26], string[20], request[1] = { type } ;
	
	write( parentWriteFileDescriptor, request, 1 ) ;
	if (  read( parentReadFileDescriptor, string, 20 ) > 0 ) {
	
		if ( writeFileDescriptor != nil ) {
			if ( string[0] == 0 ) *writeFileDescriptor = -1 ;
			else {
				strcpy( path, string ) ;
				strcat( path, "Write" ) ;
				*writeFileDescriptor = open( path, O_WRONLY ) ;
			}
		}
		if ( readFileDescriptor ) {
			if ( string[0] == 0 ) *readFileDescriptor = -1 ;
			else {
				strcpy( path, string ) ;
				strcat( path, "Read" ) ;
				*readFileDescriptor = open( path, O_RDONLY ) ;
			}
		}
	}
}

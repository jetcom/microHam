/*
 *  RouterPort.c
 *  RouterTest
 *
 *  Created by Kok Chen on 5/25/06.
  */

#import "RouterPort.h"
#import "RouterCommands.h"
#import <stdio.h>
#import <string.h>
#import <fcntl.h>

//  Open a pair of ports to the parent ports for read and write to a given type of connection
//	if one of the result pointers is nil, no open is made to that file descriptor
//	return -1 in all non-nil file descriptors of cannot open connection

void obtainRouterPorts( int *readFileDescriptor, int *writeFileDescriptor, int type, int parentReadFileDescriptor, int parentWriteFileDescriptor )
{
	char path[26], string[21], request[1] = { type } ;
	
	write( parentWriteFileDescriptor, request, 1 ) ;
	if ( read( parentReadFileDescriptor, string, 20 ) > 0 ) {
	
		if ( writeFileDescriptor != NULL ) {
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

void getKeyerID( int index, int parentReadFileDescriptor, int parentWriteFileDescriptor, char *kid )
{
	char request[2] ;
	
	request[0] = KEYERID ;
	request[1] = index ;
	write( parentWriteFileDescriptor, request, 2 ) ;		//  send { KEYERID, index }
	kid[0] = 0 ;
	read( parentReadFileDescriptor, kid, 21 ) ;
}

void obtainRouterPortsForName( int *readFileDescriptor, int *writeFileDescriptor, char *name, int parentReadFileDescriptor, int parentWriteFileDescriptor )
{
	char path[26], string[21], request[32] ;
	
	request[0] = OPENKEYER ;
	strcpy( &request[1], name ) ;
	
	write( parentWriteFileDescriptor, request, strlen(request)+1 ) ;
	
	if ( read( parentReadFileDescriptor, string, 20 ) > 0 ) {
	
		if ( writeFileDescriptor != NULL ) {
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


//
//  NamedFIFOPair.m
//  µH Router
//
//  Created by Kok Chen on 5/20/06.
	#include "Copyright.h"
	
	
#import "NamedFIFOPair.h"


//  implementation of a pair of Unix named FIFO for doing read() and write() operations

@implementation NamedFIFOPair

- (id)initWithPipeName:(const char*)fifoName
{
	int n ;
	
	self = [ super init ] ;
	if ( self ) {
	
		n = strlen( fifoName ) ;
		baseName = (char*)malloc( n+1 ) ;
		if ( baseName ) {
			strcpy( baseName, fifoName ) ;
			//  Create Read fifo
			//  As the server, we read from the client's "Write" fifo.
			inputFileDescriptor = [ self createFIFO:"Write" ] ;
			ioctl( inputFileDescriptor, O_RDONLY, 0 ) ; //  change to read-only
			//  Create Write fifo
			outputFileDescriptor = [ self createFIFO:"Read" ] ;
			ioctl( outputFileDescriptor, O_WRONLY, 0 ) ; //  change to write-only
		}
	}
	return self ;
}

//  create a FIFO whose name is the baseName appended by the type name as a read/write FIFO
//  return the fileDescriptor
- (int)createFIFO:(char*)type
{
	int fd ;
	char name[64] ;

	strcpy( name, baseName ) ;
	strcat( name, type ) ;
	//  get rid of any orphaned pipe
	unlink( name ) ;
	//  now create the named pipe
	if ( mknod( name, S_IFIFO | 0600, 0 ) == 0 ) fd = open( name, O_RDWR ) ;			
	
	return fd ;
}

- (void)dealloc
{
	char temp[48] ;

	if ( baseName ) {
		if ( inputFileDescriptor > 0 ) close( inputFileDescriptor ) ;
		if ( outputFileDescriptor > 0 ) close( outputFileDescriptor ) ;
		strcpy( temp, baseName ) ;
		strcat( temp, "Read" ) ;
		unlink( temp ) ;
		strcpy( temp, baseName ) ;
		strcat( temp, "Write" ) ;
		unlink( temp ) ;
		free( baseName ) ;
	}
	[ super dealloc ] ;
}

- (void)stopPipe
{
	if ( baseName ) {
		if ( outputFileDescriptor > 0 ) close( outputFileDescriptor ) ;
	}
}

- (const char*)name
{
	return baseName ;
}

- (int)inputFileDescriptor
{
	return inputFileDescriptor ;
}

- (int)outputFileDescriptor
{
	return outputFileDescriptor ;
}

@end

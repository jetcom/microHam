//
//  UDPTest.m
//  UDP CLient
//
//  Created by Kok Chen on 3/13/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "UDPTest.h"
#import "RouterCommands.h"


@implementation UDPTest

static struct sockaddr_in *localSocket( in_port_t port )
{
	struct sockaddr_in *sock ;
	
	sock = (struct sockaddr_in*)calloc( 1, sizeof( struct sockaddr_in ) ) ;
	
	sock->sin_family = AF_INET ;							//  create as IP
	sock->sin_addr.s_addr = inet_addr( LocalHost ) ;		//  local IP number
	sock->sin_port = htons( port ) ;						//  port
	return sock ;
}

- (int)sendUDPByte:(int)byte socket:(struct sockaddr_in*)socket
{
	unsigned char str[1] ;
	//struct sockaddr_in udp ;
	//socklen_t addrLength ;
	
	//getsockname( udpSocket, (struct sockaddr*)&udp, &addrLength ) ;
	str[0] = byte ;
	return sendto( mySocket, str, 1, 0, (struct sockaddr*)socket, sizeof( struct sockaddr ) ) ;
}

- (int)sendUDPBytes:(char*)str length:(int)length socket:(struct sockaddr_in*)socket
{
	return sendto( mySocket, str, length, 0, (struct sockaddr*)socket, sizeof( struct sockaddr ) ) ;
}

- (int)getUDPBytes:(unsigned char*)buffer length:(int)length
{
	return recv( mySocket, (char*)buffer, length, 0 ) ;
}

//  Request a UDP port to communicate with the keyer port of the router
- (struct sockaddr_in*)getKeyerUDPPort:(int)openCommand
{
	int port ;
	unsigned char buffer[4] ;

	// request port
	buffer[0] = openCommand ;
	sendto( mySocket, buffer, 1, 0, (struct sockaddr*)udpServerAddress, sizeof( struct sockaddr ) ) ;
	
	//	Read response from router
	//  Make sure that (1) the returned datagram is 3 bytes (by trying to read 4 bytes),
	//	and that (2) the first byte read contains the same openCommand byte as sent.
	
	if ( recv( mySocket, buffer, 4, 0 ) == 3 ) {
		if ( ( openCommand & 0xff ) == ( buffer[0] & 0xff ) ) {
			port = buffer[1]*256 + buffer[2] ;
			if ( port > 0 ) return localSocket( port ) ;
		}
	}
	return nil ;
}

- (void)createUDPports
{
	udpServerAddress = localSocket( mHUDPServerPort ) ;		//  mH Router master port
	myAddress = localSocket( 0 ) ;						//  our own UDP port
	udpMicroKeyerAddress = nil ;
	udpDigiKeyerAddress = nil ;
	udpCWKeyerAddress = nil ;
	
	//  Get socket of UDP port that we use to communicate
	if ( ( mySocket = socket( PF_INET, SOCK_DGRAM, IPPROTO_UDP ) ) > 0 ) {
		//  and bind socket to address of our UDP port 
		if ( bind( mySocket, (struct sockaddr*)myAddress, sizeof( struct sockaddr ) ) >= 0 ) {			
			udpMicroKeyerAddress = [ self getKeyerUDPPort:OPENMICROKEYER ] ;
			udpDigiKeyerAddress = [ self getKeyerUDPPort:OPENDIGIKEYER ] ;
			udpCWKeyerAddress = [ self getKeyerUDPPort:OPENCWKEYER ] ;
		}
	}
}

//  set up baud rate of RADIO port 
- (void)setRadioBaudRate
{
	int baudrateConst ;
	char command[] = { CONTROL_PREFIX, 0x01, 0x00, 0x00, 0x00, 0x81 } ;
	
	baudrateConst = 11059200/4800 ;				// 4800 baud
	command[2] = baudrateConst & 0xff ;
	command[3] = baudrateConst/256 ;
	command[4] = 0x64 ;							// 8 bits, 2 stop, no parity
	[ self sendUDPBytes:command length:6 socket:udpMicroKeyerAddress ] ;							
	usleep( 50000 ) ;							//  sleep for 50 ms after setting up radio channel in the keyer
}

//  set mode of FT-1000MP
- (void)setRadioMode:(int)row
{
	char command[] = { RADIO_PREFIX, 0x00, 0x00, 0x00, 0x00, 0x0c } ;
	int mode[] = { 0, 1, 3, 8, 0xa } ;

	if ( row > 4 ) row = 0 ;
	command[4] = mode[row] ;
	[ self sendUDPBytes:command length:6 socket:udpMicroKeyerAddress ] ;							
}

//  fetch VFO data from FT-1000MP (reply is printed by -watchThread (below)
- (void)getRadioVFO
{
	char command[] = { RADIO_PREFIX, 0x00, 0x00, 0x00, 0x03, 0x10 } ;
	
	[ self sendUDPBytes:command length:6 socket:udpMicroKeyerAddress ] ;							
}

- (void)radioTest
{
	[ self setRadioBaudRate ] ;
	[ self setRadioMode:1 ] ;		//  USB
	[ self getRadioVFO ] ;
}

- (void)testPTT
{
	char command[8] ;
	
	command[0] = CONTROL_PREFIX ;
	command[1] = 0x0a ;
	command[2] = 3 ;			// digital mode
	command[3] = 0x8a ;
	[ self sendUDPBytes:command length:4 socket:udpMicroKeyerAddress ] ;

	//  turn on PTT
	command[0] = PTT_PREFIX ;
	command[1] = '1' ;
	[ self sendUDPBytes:command length:2 socket:udpMicroKeyerAddress ] ;
	
	sleep( 2 ) ;
	
	//  turn off PTT
	command[0] = PTT_PREFIX ;
	command[1] = '0' ;
	[ self sendUDPBytes:command length:2 socket:udpMicroKeyerAddress ] ;
}

- (void)quitRouter
{
	char command[1] = { QUITALWAYS } ;

	sendto( mySocket, command, 1, 0, (struct sockaddr*)udpServerAddress, sizeof( struct sockaddr ) ) ;
}

- (id)init
{	
	self = [ super init ] ;
	if ( self ) {
		[ self createUDPports ] ;
		
		if ( udpMicroKeyerAddress != nil ) {
		
			// create a thread to listen to data from the microKeyer
			[ NSThread detachNewThreadSelector:@selector(watchThread:) toTarget:self withObject:self ] ;
			
			//[ self testPTT ] ;
			[ self radioTest ] ;
			//[ self quitRouter ] ;
			
			exit( 0 ) ;
		}
	}
	return self ;
}

- (void)dealloc
{
	close( mySocket ) ;
	free( udpServerAddress ) ;
	free( myAddress ) ;
	free( udpMicroKeyerAddress ) ;
	free( udpDigiKeyerAddress ) ;
	free( udpCWKeyerAddress ) ;
	[ super dealloc ] ;
}

- (void)watchThread:(id)sender
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	int n, i ;
	char buffer[1024] ;	
	
	while ( 1 ) {
		//  block indefinitely, waiting for a single byte request from the router	
		
		n = recv( mySocket, &buffer, 1024, 0 ) ;
			
		if ( n > 0 ) {
			printf( "recv: " ) ;
			for ( i = 0; i < n; i++ ) printf( "%02x ", buffer[i]&0xff ) ;
			printf( "\n" ) ;			
		}
	}
	//  abort polling when an error is seen
	[ pool release ] ;
}


@end

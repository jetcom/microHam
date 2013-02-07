/*
 *  testshell.c
 *  SerialPort
 *
 *  Created by Kok Chen on 6/15/10.
 *  Copyright 2010 Kok Chen, W7AY. All rights reserved.
 *
 */

#include "testshell.h"
#include "Keyerprotocol.h"
#include <stdio.h>
#include <unistd.h>
#include <termios.h>
#include <fcntl.h>

//  open as read/write, 230000 baud, no parity, one stop
//	returns Unix fd
int openPort( const char *path )
{
	int fd ;
	struct termios options ;
	
	fd = open( path, O_RDWR ) ;
	if ( fd < 0 ) return fd ;

	if ( fcntl( fd, F_SETFL, 0 ) >= 0 ) {
		// Get the current options and save them for later reset
		// These options are documented in the man page for termios
		tcgetattr( fd, &options ) ;
		// set device to 230400 baud, 8 bits no parity,one stop
		options.c_cflag = (CS8) | (CREAD) | (CLOCAL) ;	// set flags before speed for Linux compatibility
		cfsetispeed( &options, B230400 ) ;
		cfsetospeed( &options, B230400 ) ;
		// Set raw input, 1 minute timeout
		options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
		options.c_oflag &= ~OPOST;
		options.c_cc[ VMIN ] = 0 ;
		options.c_cc[ VTIME ] = 1 ;			//  1/10 second time out
		// Set the options
		tcsetattr( fd, TCSANOW, &options ) ;
		return fd ;
	}
	return ( -1 ) ;
}

void testShell()
{
	int fd, i, byte ;
	const char *microKeyer = "/dev/cu.usbserial-M2Q5BDJC" ;
	unsigned char split[] = { 0x0, 0x0, 0x0, 0x1, 0x1 } ;
	unsigned char vfoData[] = { 0x0, 0x0, 0x0, 0x3, 0x10 } ;
	
	fd = openPort( microKeyer ) ;
	if ( fd < 0 ) {
		printf( "cannot open microKeyer %s\n", microKeyer ) ;
		return ;
	}
	
	setRadio1Params( fd, 4800, 2, 8 ) ;			//  set radio baud rate
	sleep( 1 ) ;
	writeRadioBuffer( fd, 0, split, 5 ) ;		//  set split mode
	sleep( 1 ) ;
	writeRadioBuffer( fd, 0, vfoData, 5 ) ;		//  get VFO A and B data (should get 32 bytes back)
	
	//  read from Radio 1 until timed out
	for ( i = 0; i < 64; i++ ) {
		byte = getRadio( fd, 0 ) ;
		if ( byte < 0 ) break ;
		printf( "read byte %2d: 0x%02x\n", i, byte ) ;
	}
	
	close( fd ) ;
}

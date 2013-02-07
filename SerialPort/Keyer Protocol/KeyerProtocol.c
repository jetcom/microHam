/*
 *  KeyerProtocol.c
 *  SerialPort
 *
 *  Created by Kok Chen on 6/15/10.
 *  Copyright 2010 Kok Chen, W7AY. All rights reserved.
 *
 */

#include "KeyerProtocol.h"

#include <unistd.h>
#include <stdio.h>

//  send bytes to file descriptor
void writeControl( int fd, unsigned char *bytes, int length )
{
	write( fd, bytes, length ) ;
}

//  Send CAT data to radio
//		fd is file descriptor of an opened serial port
//		channel = 0 for Radio 1 and channel = 1 for Radio 2 (if the keyer supports it)
void writeRadio( int fd, int channel, int byte )
{
	unsigned char nop[] = { 0x28, 0x80, 0x80, 0x80 } ;	//  single Keyer Protocol frame
		
	if ( channel > 1 ) return ;

	if ( channel == 1 ) {
		if ( byte & 0x80 ) nop[0] |= 2 ;				// MS bit of radio2 data
		nop[2] |= byte ;								// 7 LSB of data
	}
	else {
		if ( byte & 0x80 ) nop[0] |= 4 ;				// MS bit of radio1 data
		nop[1] |= byte ;								// 7 LSB of data
	}
	writeControl( fd, nop, 4 ) ;
}

//  Send multiple bytes to radio
//		fd is file descriptor of an opened serial port
//		channel = 0 for Radio 1 and channel = 1 for Radio 2 (if the keyer supports it)
void writeRadioBuffer( int fd, int channel, unsigned char *bytes, int length )
{
	int i ;
	
	for ( i = 0; i < length; i++ ) writeRadio( fd, channel, bytes[i] ) ;
}


int getRadio( int fd, int channel )
{
	unsigned char byte, frameByte ;
	int value, count, sync ;
	
	sync = 4 ;		//  some large number
	while ( 1 ) {
		count = read( fd, &byte, 1 ) ;
		if ( count == 0 ) return ( -1 ) ;					//  port timed out (controlled by VTIME in termios)
		//  lookfor frame sync
		if ( ( byte & 0x80 ) == 0 ) {
			//  found sync
			sync = 0 ;
			frameByte = byte ;
		}
		else {
			// not sync
			sync++ ;
			//  radio 1 is at sync = 1 if there is also a valid flag for it
			if ( sync == 1 && ( frameByte & 0x20 ) != 0 && channel == 0 ) {
				//  got valid radio 1 data, merge in its MSB from frameByte
				value = byte & 0x7f ;
				if ( frameByte & 0x4 ) value |= 0x80 ;		//  fetch MSB of radio 1 from first byte of frame
				return value ;
			}
			//  radio 2 is at sync = 2 if there is also a valid flag for it
			if ( sync == 2 && ( frameByte & 0x10 ) != 0 && channel == 1 ) {
				//  got valid radio 2 data, merge in its MSB from frameByte
				value = byte & 0x7f ;
				if ( frameByte & 0x2 ) value |= 0x80 ;		//  fetch MSB of radio 2 from first byte of frame
				return value ;
			}
			//  otherwise ignore this byte of a frame
		}
	}
}

//	Send a single control byte to the keyer
//		The control byte is sent in last byte of the second frame of a sequence.
//		Because of that, when nothing else is sent, we need to send a dummy frame first.
//		Each control byte therefore takes 8 bytes to send (two 4 byte frames).
//		The "validity bit" (sic) is off for the first and last byte of a control string.
static void writeControlByte( int fd, int byte, int isValid )
{
	unsigned char nop[] = { 0x08, 0x80, 0x80, 0x80, 0x40, 0x80, 0x80, 0x80 } ;

	nop[4] |= ( isValid ) ? 0x08 : 0x00 ;				// valid 0x08 or 0x00
	if ( byte & 0x80 ) nop[4] |= 1 ;					// MSB of control data
	nop[7] |= byte ;									// 7 bit control with MSB set	
	writeControl( fd, nop, 8 ) ;
}

static void writeControlString( int fd, unsigned char *bytes, int length )
{
	int i ;
	
	for ( i = 0; i < length; i++ ) writeControlByte( fd, bytes[i], !( i==0 || i==(length-1) ) ) ;
}

static const int stops[] = { 0, 0, 0x4, 0x08 } ;
static const int bits[] = { 0x60, 0x60, 0x60, 0x60, 0x60, 0x00, 0x20, 0x40, 0x60 } ;

static void setRadioParams( int fd, unsigned char *command, int length, int baud, int stopbits, int databits )
{
	int baudrateConst ;
	
	baudrateConst = 11059200/baud ;
	command[1] = baudrateConst & 0xff ;
	command[2] = baudrateConst/256 ;
	command[3] = bits[databits] | stops[stopbits] ;
	writeControlString( fd, command, length ) ;	
}

//  set radio parameters for old (MK only) keyers
//		stopbits = 0,1 for 1 stop bit, 2 for 2 stop bits and 3 for 1.5 stop bits
void setOldRadioParams( int fd, int baud, int stopbits, int databits )
{
	unsigned char command[] = { 0x01, 0x00, 0x00, 0x00, 0x81 } ;
	setRadioParams( fd, command, 5, baud, stopbits, databits ) ;
}

//  set radio 1 parameters for (MK2, MK2R and SM only) keyers
//		Note that the 0xfe byte turns off any internal keyer decoding
//		stopbits = 0,1 for 1 stop bit, 2 for 2 stop bits and 3 for 1.5 stop bits
void setRadio1Params( int fd, int baud, int stopbits, int databits )
{
	unsigned char command[] = { 0x01, 0x00, 0x00, 0x00, 0xfe, 0x00, 0x00, 0x81 } ;
	setRadioParams( fd, command, 8, baud, stopbits, databits ) ;
}

//  set radio 1 parameters for (MK2, MK2R and SM only) keyers
//		Note that the 0xfe byte turns off any internal keyer decoding
//		stopbits = 0,1 for 1 stop bit, 2 for 2 stop bits and 3 for 1.5 stop bits
void setRadio2Params( int fd, int baud, int stopbits, int databits )
{
	unsigned char command[] = { 0x02, 0x00, 0x00, 0x00, 0xfe, 0x00, 0x00, 0x82 } ;
	setRadioParams( fd, command, 8, baud, stopbits, databits ) ;
}



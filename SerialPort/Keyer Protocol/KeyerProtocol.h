/*
 *  KeyerProtocol.h
 *  SerialPort
 *
 *  Created by Kok Chen on 6/15/10.
 *  Copyright 2010 Kok Chen, W7AY. All rights reserved.
 *
 */

//	send single byte to radio
void writeRadio( int fd, int channel, int byte ) ;

//	get radio byte.  Returns -1 if timed out.
int getRadio( int fd, int channel ) ;

//  send buffer to radio
void writeRadioBuffer( int fd, int channel, unsigned char *bytes, int length ) ;

//  set up old (MK) radio parameters
void setOldRadioParams( int fd, int baud, int stopbits, int databits ) ;

//  set up new (MK2, MK2R, SM) radio 1 parameters
void setRadio1Params( int fd, int baud, int stopbits, int databits ) ;

//  set up new (MK2, MK2R, SM) radio 2 parameters
void setRadio2Params( int fd, int baud, int stopbits, int databits ) ;

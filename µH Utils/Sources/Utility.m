//
//  Utility.m
//  µH Utils
//
//  Created by Kok Chen on 7/21/06.

#import "Utility.h"
#include "Controller.h"

@implementation Utility

#define Log( debug, s,... )	{ NSLog( [ NSString stringWithCString:s ], ##__VA_ARGS__ ) ; }

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		debug = NO ;
		client = nil ;
		frameSequence = 0 ;
	}
	return self ;
}

- (id)initWithClient:(Controller*)inClient 
{
	self = [ self init ] ;
	if ( self ) {
		client = inClient ;
	}
	return self ;
}

- (void)sendControl:(unsigned char*)input length:(int)length to:(int)fd
{
	unsigned char ctrl[8] = { 0x08, 0x80, 0x80, 0x80, 0x40, 0x80, 0x80, 0x80 } ;
	int i ;
	
	for ( i = 0; i < length; i++ ) {
		ctrl[4] = ( i == 0 || i == ( length-1 ) ) ? 0x40 : 0x48 ;
		if ( input[i] & 0x80 ) ctrl[4] |= 0x01 ;
		ctrl[7] = input[i] | 0x80 ;
		write( fd, ctrl, 8 ) ;
	}
}

- (void)sendBytes:(unsigned char*)input length:(int)length to:(int)fd
{
	write( fd, input, length ) ;
}

- (int)waitForBuffer:(unsigned char*)buffer length:(int)bytes timeout:(float)seconds
{
	int i, loop, n ;
	
	loop = seconds/0.025 ;
	if ( loop <= 1 ) {
		if ( seconds > 0.0 ) [ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:seconds ] ] ;	
		n = [ client buflen ] ;
		if ( n >= bytes ) {
			[ client read:buffer length:bytes ] ;
			return bytes ;
		}
	}
	
	for ( i = 0; i < loop; i++ ) {
		[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:0.025 ] ] ;		// 25 ms sleep
		n = [ client buflen ] ;
		if ( n >= bytes ) {
			[ client read:buffer length:bytes ] ;
			return bytes ;
		}
	}
	return [ client buflen ] ;
}


- (Boolean)getFrame:(unsigned char*)buf
{
	int i, v ;
	
	//  find first byte of frame
	for ( i = 0; i < 16; i++ ) {
		v = *parsePoint ;
		if ( ( v & 0x80 ) == 0 ) break ;
	}
	*buf++ = v ;
	for ( i = 0; i < 3; i++ ) {
		if ( ( parsePoint - parseHead ) < parseLength ) {
			parsePoint++ ;
			v = *parsePoint ;
			if (  ( v & 0x80 ) == 0 ) return NO ;
			*buf++ = v ;
		}
		else return NO ;
	}
	if ( ( parsePoint - parseHead ) < parseLength ) parsePoint++ ;
	return YES ;
}

- (int)getControlByte
{
	unsigned char frame[4] ;
	int i, v ;
	Boolean status ;
	
	for ( i = 0; i < 8; i++ ) {
		status = [ self getFrame:frame ] ;
		if ( status ) {
			if ( ( frame[0] & 0x40 ) == 0 ) frameSequence = 0 ; else frameSequence++ ;
			if ( frameSequence == 1 ) {
				v = frame[3] & 0x7f ;
				if ( frame[0] & 0x1 ) v |= 0x80 ;
				return v ;
			}
		}
		else return ( -1 ) ;
	}
	return 0 ;
}

//  simple keyer protocol parser for CONTROL stream 
- (int)parse:(unsigned char*)input length:(int)length intoControl:(unsigned char*)control
{
	int n, i ;
	
	parseHead = parsePoint = input ;
	parseLength = length ;
	
	for ( i = 0; i < 32; i++ ) {
		if ( ( parsePoint - parseHead ) >= length ) break ;
		n = [ self getControlByte ] ;	
		if ( n < 0 ) break ;
		*control++ = n & 0xff ;	
	}
	return i ;
}

//  return yes if Version structs contain proper values
- (Boolean)getVersion:(Version*)appl bootloader:(Version*)boot from:(int)fd
{
	unsigned char getVersion[2] = { 0x05, 0x85 }, buffer[64], ctrl[8] ;
	int i, n ;

	appl->major = appl->minor = 0 ;
	boot->major = boot->minor = 0 ;
	//  initial check to make sure keyer can receive data, Control: 0x7e 0xfe
	[ self sendControl:getVersion length:2 to:(int)fd ] ;
	
	n = [ self waitForBuffer:buffer length:8 timeout:0.25 ] ;
	if ( n != 8 ) return NO ; 
	
	n = [ self parse:buffer length:8 intoControl:ctrl ] ;
	if ( n != 1 || ctrl[0] != 0x05 ) return NO ;

	n = [ self waitForBuffer:buffer length:64 timeout:0.05 ] ;
	if ( n != 64 ) return NO ;
	n = [ self parse:buffer length:64 intoControl:ctrl ] ;
	boot->major = ctrl[1] ;
	boot->minor = ctrl[0] ;
	boot->mechanical = ctrl[4] ;
	boot->hardware = ctrl[3] ;
	
	n = [ self waitForBuffer:buffer length:64 timeout:0.05 ] ;
	if ( n != 64 ) return NO ;
	n = [ self parse:buffer length:64 intoControl:ctrl ] ;
	appl->major = ctrl[1] ;
	appl->minor = ctrl[2] ;
	appl->mechanical = ctrl[3] ;
	appl->hardware = ctrl[4] ;

	//  look for end
	for ( i = 0; i < 8; i++ ) {
		n = [ self waitForBuffer:buffer length:8 timeout:0.05 ] ;
		if ( n != 8 ) break ;
		n = [ self parse:buffer length:8 intoControl:ctrl ] ;
		if ( ctrl[0] == 0x85 ) return YES ;
	}
	//  did not find end og GET VERSION string??!
	return NO ;
}

@end

//
//  ReplyBuf.m
//  µH Router
//
//  Created by Kok Chen on 6/3/06.
	#include "Copyright.h"

#import "ReplyBuf.h"


@implementation ReplyBuf

//  Reply buffer for AppleScripting
- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		producer = consumer = 0 ;
		dataLock = [ [ NSLock alloc ] init ] ;
	}
	return self ;
}

- (NSString*)get
{
	NSString *string ;
	int i, j ;
	
	[ dataLock lock ] ;
	if ( producer == consumer ) string = @"" ;
	else {
		i = consumer ;
		for ( j = 0; j < 1024; j++ ) {
			if ( i == producer ) break ;
			temp[j] = buffer[i] ;
			i = ( i + 1 ) & 0x3ff ;
		}
		temp[j] = 0 ;
		string = [ NSString stringWithCString:temp ] ;
	}
	consumer = producer ;
	[ dataLock unlock ] ;
	return string ;
}

static int hex( int v )
{
	v &= 0xf ;
	if ( v >= 0 && v <= 9 ) return '0' + v ;
	return 'a' + ( v - 10 ) ;
}

static int invalidHex( int v )
{
	v &= 0xf ;
	if ( v >= 0 && v <= 9 ) return 'P' + v ;
	return 'A' + ( v - 10 ) ;
}

//	NOTE: append a byte into two encoded ASCII hex
- (void)append:(int)value
{
	[ dataLock lock ] ;
	buffer[producer] = hex( value/16 ) ;
	producer = ( producer + 1 ) & 0x3ff ;
	buffer[producer] = hex( value ) ;
	producer = ( producer + 1 ) & 0x3ff ;
	[ dataLock unlock ] ;
}

//	NOTE: append a byte that is marked as "invalid" into two encoded AXCII hex
- (void)appendInvalid:(int)value
{
	[ dataLock lock ] ;
	buffer[producer] = invalidHex( value/16 ) ;
	producer = ( producer + 1 ) & 0x3ff ;
	buffer[producer] = invalidHex( value ) ;
	producer = ( producer + 1 ) & 0x3ff ;
	[ dataLock unlock ] ;
}

- (void)reset
{
	[ dataLock lock ] ;
	producer = consumer = 0 ;
	[ dataLock unlock ] ;
}

@end

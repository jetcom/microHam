//
//  Downloader.m
//  µDownloader
//
//  Created by Kok Chen on 7/21/06.


#import "Downloader.h"
#include "Controller.h"


@implementation Downloader

#define Log( debug, s,... )	//{ NSLog( [ NSString stringWithCString:s ], ##__VA_ARGS__ ) ; }

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		fileChecked = YES ;
		flashBlocks = 0 ;
	}
	return self ;
}

- (void)awakeFromNib
{
	[ progressField setStringValue:@" " ] ;
}

- (FILE*)openFirmwareFile:(NSString*)folder
{
	NSOpenPanel *open ;
	NSString *path ;
	FILE *fd ;
	int result ;

	open = [ NSOpenPanel openPanel ] ;
	[ open setAllowsMultipleSelection:NO ] ;
	[ open setCanChooseDirectories:NO ] ;
	
	result = [ open runModalForDirectory:folder file:nil types:[ NSArray arrayWithObjects:@"cbl", nil ] ] ;
	
	if ( result == NSOKButton ) {
		path = [ [ open filenames ] objectAtIndex:0 ] ;			
		fd = fopen( [ path UTF8String ], "rb" ) ;
		return fd ;
	}
	return nil ;
}

- (Boolean)loadFile:(NSString*)folder
{
	FILE *f ;
	int type, length, i ;
	Boolean done, finished ;
	
	[ progressField setStringValue:@" " ] ;
	f = [ self openFirmwareFile:folder ] ;
	if ( !f ) return NO ;
	
	printf( "has file\n" ) ;
	
	flashBlocks = 0 ;
	done = finished = NO ;
	while ( !done ) {
		type = fgetc( f ) ;
		if ( type <= 0 ) {
			done = finished = YES ;
		}
		else {
			type &= 0xff ;
			length = fgetc( f ) & 0xff ;
			switch ( type ) {
			case 0x20:
				for ( i = 0; i < length; i++ ) fgetc( f ) ;
				break ;
			case 0x03:
				if ( length > 16 ) done = YES ;
				else {
					fread( fileVersion, length, 1, f ) ;
					Log( debug, "Firmware file version %d.%d product type %d\n", fileVersion[4], fileVersion[3], fileVersion[0] ) ;
				}
				break ;
			case 0x01:
				if ( length > 160 ) {
					done = YES ;
				}
				else {
					fread( flash[flashBlocks].data, length, 1, f ) ;
					flash[flashBlocks].length = length ;
				}
				/*
				printf( "flash block %3d:", flashBlocks ) ;
				for ( i = 0; i < 2; i++ ) {
					printf( "%02x ", flash[flashBlocks].data[i] ) ;
				}
				printf( "... " ) ;
				for ( i = 4; i < 6; i++ ) {
					printf( "%02x ", flash[flashBlocks].data[i+0x40] ) ;
				}
				printf( "\n" ) ;
				*/
				flashBlocks++ ;
				if ( flashBlocks >= 1023 ) done = YES ;
				break ;
			default:
				done = YES ;
				printf( "Error with type = 0x%02x length = 0x%02x\n", type,length ) ;
				break ;
			}
		}
	}
	fclose( f ) ;
	
	return finished ;
}

- (int)downloadTo:(int)fd client:(Controller*)inClient
{
	unsigned char areYouThere[2] = { 0x7e, 0xfe } ;
	unsigned char startBootloader[2] = { 0x06, 0x86 } ;
	unsigned char buffer[256] ;
	int n, state ;
	
	client = inClient ;
	
	if ( !fileChecked ) return kBadDownloadFile ;
	
	//  initial check to make sure keyer can receive data, Control: 0x7e 0xfe
	[ self sendControl:areYouThere length:2 to:(int)fd ] ;
	Log( debug, "[7e fe sent]\n" ) ;
	n = [ self waitForBuffer:buffer length:16 timeout:0.25 ] ;
	if ( n != 16 ) {
		Log( debug, "No/bad response from keyer.\n" ) ;
		[ client outputMessage:@"No/bad response from keyer." ] ;
		return kNoResponseFromKeyer ;
	}
	if ( debug ) [ self controlResponse:buffer length:16 ] ;
	
	[ client outputMessage:@"Starting bootloader..." ] ;
	
	//  send Control: 0x06 0x86
	[ self sendControl:startBootloader length:2 to:fd ] ;
	Log( debug, "[06 86 sent]\n" ) ;
	n = [ self waitForBuffer:buffer length:16 timeout:0.25 ] ;
	if ( n != 16 ) {
		Log( debug, "Cannot start bootloader.\n" ) ;
		return kCannotStartBootloader ;
	}
	if ( debug ) [ self controlResponse:buffer length:16 ] ;
	
	state = [ self bootloadTo:fd client:client ] ;
	
	[ client outputMessage:@"Done!  Please disconnect now." ] ;
	
	return state ;
}

- (int)bootloadTo:(int)fd client:(Controller*)inClient
{
	unsigned char bootloaderCommandStart[1] = { 0x42 } ;
	unsigned char bootloaderGetVersion[1] = { 0x43 } ;
	unsigned char nextPage[1] = { 0x44 } ;
	unsigned char buffer[256] ;
	float progress ;
	int i, n ;
	
	if ( !fileChecked ) return kBadDownloadFile ;
	

	client = inClient ;
	[ client resetBuffer ] ;
	
	//  send 0x42, expect 0x01 back
	[ self sendBytes:bootloaderCommandStart length:1 to:fd ] ;
	Log( debug, "[MMK_BLCMD_START sent]\n" ) ;
	n = [ self waitForBuffer:buffer length:1 timeout:1.5 ] ;
	if ( n != 1 ) {
		Log( debug, "Bootloader sequence did not start, no data received.\n", n ) ;
		return kBootloaderDidNotStart ;
	}
	if ( buffer[0] != 0x01 ) {
		Log( debug, "Bootloader sequence did not start, wrong response from keyer (expect 01).\n" ) ;
		return kBootloaderDidNotStart ;
	}
	Log( debug, "[MMK_BLCMD_STARTED received]\n" ) ;

	//  send 0x43, expect 0x02 back
	[ self sendBytes:bootloaderGetVersion length:1 to:fd ] ;
	Log( debug, "[MMK_BLCMD_GET_VERSION sent]\n" ) ;
	n = [ self waitForBuffer:buffer length:1 timeout:0.125 ] ;
	if ( n != 1 || buffer[0] != 2 ) {
		Log( debug, "Bad Version\n" ) ;
		return kBadVersion ;
	}
	n = [ self waitForBuffer:bootloaderVersion length:8 timeout:0.05 ] ;
	if ( n != 8 ) {
		Log( debug, "Bad Version, received %d bytes instead of 8\n", n ) ;
		return kBadVersion ;
	}
	if ( buffer[0] != 2 ) {
		Log( debug, "Bad Version.\n" ) ;
		return kBadVersion ;
	}
	for ( n = 0; n < 8; n++ ) bootloaderVersion[n] &= 0x7f ;
	Log( debug, "[MMK_BLCMD_VERSION received]\n" ) ;
	Log( debug, "[Bootloader Version %d.%d]\n", bootloaderVersion[1], bootloaderVersion[0] ) ;
	Log( debug, "[Product type %d]\n", bootloaderVersion[2] ) ;
	Log( debug, "[Hardware version %d]\n", bootloaderVersion[3] ) ;
	Log( debug, "[Mechanical version %d]\n", bootloaderVersion[4] ) ;
	
	buffer[0] = 0 ;
	for ( i = 0; i < flashBlocks; i++ ) {
		[ self sendBytes:nextPage length:1 to:fd ] ;
		[ self sendBytes:flash[i].data length:flash[i].length to:fd ] ;
		progress = i*100.0/flashBlocks ;
		[ progressBar setDoubleValue:progress ] ;
		[ progressField setStringValue:[ NSString stringWithFormat:@"%.0f%%", progress ] ] ;
		n = [ self waitForBuffer:buffer length:1 timeout:1.0 ] ;
		if ( n != 1 || buffer[0] != 3 ) {
			Log( debug, "Bad Version\n" ) ;
			break ;
		}
	}
	[ progressField setStringValue:@"Done" ] ;
		
	return kSuccess ;
}

- (void)controlResponse:(unsigned char*)str length:(int)length
{
	int i, n ;
	unsigned char ctrl[256] ;
	char string[512], added[16] ;
	
	n = [ self parse:str length:length intoControl:ctrl ] ;
	
	sprintf( string, "CONTROL: " ) ;
	for ( i = 0; i < n; i++ ) {
		sprintf( added, "%02x ", ctrl[i] ) ;
		strcat( string, added ) ;
	}
	strcat( string, "\n" ) ;
	Log( debug, string ) ;
}



@end

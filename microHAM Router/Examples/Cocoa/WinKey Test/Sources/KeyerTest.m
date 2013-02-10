//
//  KeyerTest.m
//  RouterTest
//
//  Created by Kok Chen on 5/25/06.

#import "KeyerTest.h"
#include "RouterCommands.h"


@implementation KeyerTest

#define	PTTPORT		1
#define	CWPORT		2
#define	WINKEYPORT	3
#define	CONTROLPORT	4
#define	RADIOPORT	5


- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (id)initIntoTabView:(NSTabViewItem*)tabviewItem read:(int)readDiscriptor write:(int)writeDiscriptor 
{
	self = [ super init ] ;
	if ( self ) {
		keyerRead = readDiscriptor ;
		keyerWrite = writeDiscriptor ;

		if ( [ NSBundle loadNibNamed:@"KeyerTest" owner:self ] ) {

			// loadNib should have set up contentView connection
			if ( view ) {
			
				radioParamsSet = NO ;
				parseVFO = NO ;
				radioBusy = [ [ NSLock alloc ] init ] ;
				
				//  create a new TabViewItem for config
				[ tabviewItem setView:view ] ;
				
				//  connect actions
				[ self setInterface:pttButton to:@selector(pttChanged:) ] ;
				[ self setInterface:cwButton to:@selector(cwChanged:) ] ;
				[ self setInterface:winkeyButton to:@selector(sendWinkey:) ] ;
				[ self setInterface:radioModes to:@selector(changeRadioMode:) ] ;
				[ self setInterface:getVFO to:@selector(updateVFO:) ] ;
				
				//  get ptt and cw read and write ports to the DIGI KEYER
				obtainRouterPorts( &pttRead, &pttWrite, OPENPTT, keyerRead, keyerWrite ) ;
				obtainRouterPorts( &cwRead, &cwWrite, OPENCW, keyerRead, keyerWrite ) ;
				obtainRouterPorts( &winkeyRead, &winkeyWrite, OPENWINKEY, keyerRead, keyerWrite ) ;
				obtainRouterPorts( &controlRead, &controlWrite, OPENCONTROL, keyerRead, keyerWrite ) ;
				obtainRouterPorts( &radioRead, &radioWrite, OPENRADIO, keyerRead, keyerWrite ) ;
				
				//  check if device has WinKey
				if ( winkeyWrite <= 0 ) {
					[ winkeyButton setEnabled:NO ] ;
					[ winkeyMessage setEnabled:NO ] ;
				}
				//  create thread to listen to messages from the opened ports
				[ NSThread detachNewThreadSelector:@selector(pollThread:) toTarget:self withObject:self ] ;
				
				return self ;
			}
		}
	}
	return nil ;
}

- (void)dealloc
{
	char request = CLOSEKEYER ;
	
	//  ask Router to close and release our ports
	write( keyerWrite, &request, 1 ) ;
	close( keyerRead ) ;
	close( keyerWrite ) ;
	[ super dealloc ] ;
}

//  set select set (fd_set) and type array and largest fd, used by -pollThread
static void setSelectInfo( int fd, fd_set *set, int fdtype, int *type, int *largestfd )
{
	if ( fd > 0 ) {
		FD_SET( fd, set ) ;
		type[fd] = fdtype ;
		if ( fd > *largestfd ) *largestfd = fd ;
	}
}

- (void)pollThread:(id)sender
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	fd_set selectSet, readSet ;
	int fd, count, selectSetSize, type[FD_SETSIZE] ;
	unsigned char tempBuffer[40] ;  // this was 32, not long enough for a GET VERSION -- found by K1GQ

	//  First initialize fd_set and type array
	FD_ZERO( &selectSet ) ;
	selectSetSize = 0 ;
	bzero( type, FD_SETSIZE*sizeof( int ) ) ;

	//  Now set up the select set to listen to CW(flags), PTT(flags), RADIO, WINKEY and CONTROL channels
	setSelectInfo( cwRead, &selectSet, CWPORT, type, &selectSetSize ) ;
	setSelectInfo( pttRead, &selectSet, PTTPORT, type, &selectSetSize ) ;
	setSelectInfo( radioRead, &selectSet, RADIOPORT, type, &selectSetSize ) ;
	setSelectInfo( winkeyRead, &selectSet, WINKEYPORT, type, &selectSetSize ) ;
	setSelectInfo( controlRead, &selectSet, CONTROLPORT, type, &selectSetSize ) ;
	selectSetSize++ ;
		
	//  Start polling.  select() blocks until one or more file descriptors has data
	while ( 1 ) {
		//  poll the full set
		FD_COPY( &selectSet, &readSet ) ;	
		count = select( selectSetSize, &readSet, nil, nil, nil ) ;
		if ( count < 0 ) break ;		//  abort polling when an error is seen
		if ( count > 0 ) {
			for ( fd = 0; fd < selectSetSize; fd++ ) {
				if ( FD_ISSET( fd, &readSet ) ) {
					//  port has data
					switch ( type[fd] ) {
					case PTTPORT:
					case CWPORT:
					case WINKEYPORT:
					case CONTROLPORT:
						//  Nothing to do, just flush the pipe by reading as much data as we can from the fd
						//  Most often, this is just the two byte ARE_YOU_THERE response from the keyer's control channel
						count = read( fd, tempBuffer, 40 ) ;
						break ;
					case RADIOPORT:
						//  read a byte at a time from radio port.  
						//  select() will keep calling us until done
						count = read( fd, tempBuffer, 1 ) ;
						if ( count > 0 ) [ self handleRadioData:tempBuffer[0] ] ;
						break ;
					default:
						//  should not get here, just flush the data
						read( fd, tempBuffer, 40 ) ;
					}
				}
			}
		}
	}
	[ pool release ] ;
}


//  RADIO data sent from the Router
- (void)handleRadioData:(int)data
{
	int MHz, kHz, fraction ;
	NSTextField *vfoField ;
	
	if ( parseVFO ) {
		switch ( radioParserSequence ) {
		case 0:
		case 16:
			encodedVFO = 0 ;
			break ;
		case 1:
		case 2:
		case 3:
		case 4:
		case 17:
		case 18:
		case 19:
		case 20:
			encodedVFO = ( encodedVFO*256 ) + data ;
			break ;
		case 5:
		case 21:
			//  main/sub VFO frequency received
			vfoField = ( radioParserSequence == 5 ) ? mainVFO : subVFO ;
			fraction = encodedVFO / 16.0 ;
			kHz = fraction/100 ;
			fraction -= kHz*100 ;
			MHz = kHz/1000 ;
			kHz -= MHz*1000 ;
			[ vfoField setStringValue:[ NSString stringWithFormat:@"%02d.%03d.%2d", MHz, kHz, fraction ] ] ;
			break ;
		case 31:
			// turn of VFO parser and unlock the radio
			parseVFO = NO ;
			[ radioBusy unlock ] ;
		}
		radioParserSequence++ ;
	}
}

- (void)pttChanged:(id)sender
{
	if ( [ sender state ] == NSOnState ) {
		[ sender setTitle:@"Unkey PTT" ] ;
		if ( pttWrite > 0 ) write( pttWrite, "1", 1 ) ;
	}
	else {
		[ sender setTitle:@"Key PTT" ] ;
		if ( pttWrite > 0 ) write( pttWrite, "0", 1 ) ;
	}
}

- (void)cwChanged:(id)sender
{
	if ( [ sender state ] == NSOnState ) {
		[ sender setTitle:@"Unkey CW" ] ;
		if ( cwWrite > 0 ) write( cwWrite, "1", 1 ) ;	
	}
	else {
		[ sender setTitle:@"Key CW" ] ;
		if ( cwWrite > 0 ) write( cwWrite, "0", 1 ) ;	
	}
}

//	See http://k1el.tripod.com/Winkey10.pdf for Prosigns
//  for this test program, Prosigns are placed under square brackets, e.g., [AR]
- (void)sendWinkey:(id)sender
{
	unsigned char output[4];
	int i ;
	
	output[0] = 5 ;
	for ( i = 0; i < 2; i++ ) output[i+1] = [ [ winkeyMessage cellAtRow:0 column:i ] intValue ] ;
	output[3] = 255 ;
	write( winkeyWrite, output, 4 ) ;
}

- (void)setRadioParams
{
	int baudrateConst ;
	unsigned char command[] = { 0x01, 0x00, 0x00, 0x00, 0x81 } ;
	
	baudrateConst = 11059200/4800 ;				// 4,800 baud
	command[1] = baudrateConst & 0xff ;
	command[2] = baudrateConst >> 8 ;
	command[3] = 0x64 ;							// 8 bits, 2 stop, no parity
	write( controlWrite, command, 5 ) ;	
	usleep( 50000 ) ;							//  sleep for 50 ms after setting up radio channel in the keyer
	radioParamsSet = YES ;
}

//  select LSB, USB, CW, RTTY, PKT modes from NSMatrix and change FT-1000MP mode
- (void)changeRadioMode:(id)sender
{
	unsigned char command[] = { 0x00, 0x00, 0x00, 0x00, 0x0c } ;
	int row, mode[] = { 0, 1, 3, 8, 0xa } ;

	if ( !radioParamsSet ) [ self setRadioParams ] ;
	
	row = [ sender selectedRow ] ;
	if ( row > 4 ) row = 0 ;
	command[3] = mode[row] ;
	write( radioWrite, command, 5 ) ;
}

//  fetch VFO frequency from FT-1000MP
- (void)updateVFO:(id)sender
{
	unsigned char command[] = { 0x00, 0x00, 0x00, 0x03, 0x10 } ;

	if ( !radioParamsSet ) [ self setRadioParams ] ;
	
	if ( [ radioBusy tryLock ] ) {
		//  don't send VFO request if we are not in the middle of waiting for something from the radio
		parseVFO = YES ;
		radioParserSequence = 0 ;
		write( radioWrite, command, 5 ) ;
	}
}


@end

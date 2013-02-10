//
//  KeyerTest.m
//  RouterTest
//
//  Created by Kok Chen on 5/25/06.

#import "KeyerTest.h"
#import "RouterCommands.h"


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
		looping = nil ;
		keyerRead = readDiscriptor ;
		keyerWrite = writeDiscriptor ;
		
		if ( [ NSBundle loadNibNamed:@"KeyerTest" owner:self ] ) {

			// loadNib should have set up contentView connection
			if ( view ) {
			
				radioParamsSet = NO ;
				parseVFO = parseK3VFO = NO ;
				radioBusy = [ [ NSLock alloc ] init ] ;
				
				//  create a new TabViewItem for config
				[ tabviewItem setView:view ] ;
				
				//  connect actions
				[ self setInterface:pttButton to:@selector(pttChanged:) ] ;
				[ self setInterface:cwButton to:@selector(cwChanged:) ] ;
				[ self setInterface:winkeyButton to:@selector(sendWinkey:) ] ;
				[ self setInterface:fskButton to:@selector(sendFSK:) ] ;
				[ self setInterface:radioModes to:@selector(changeRadioMode:) ] ;
				[ self setInterface:getVFO to:@selector(updateVFO:) ] ;
				
				[ self setInterface:k3RadioModes to:@selector(k3ChangeRadioMode:) ] ;
				[ self setInterface:k3GetVFO to:@selector(k3UpdateVFO:) ] ;

				
				//  get ptt and cw read and write ports to the DIGI KEYER
				obtainRouterPorts( &pttRead, &pttWrite, OPENPTT|WRITEONLY, keyerRead, keyerWrite ) ;					//  v1.30 write-only
				obtainRouterPorts( &cwRead, &cwWrite, OPENCW|WRITEONLY, keyerRead, keyerWrite ) ;						//  v1.30 write-only
				obtainRouterPorts( &winkeyRead, &winkeyWrite, OPENWINKEY|WRITEONLY, keyerRead, keyerWrite ) ;			//  v1.30 write-only
				obtainRouterPorts( &fskRead, &fskWrite, OPENFSK|WRITEONLY, keyerRead, keyerWrite ) ;					//  v1.30 write-only
				obtainRouterPorts( &controlRead, &controlWrite, OPENCONTROL|WRITEONLY, keyerRead, keyerWrite ) ;		//  v1.30 write-only
				obtainRouterPorts( &radioRead, &radioWrite, OPENRADIO, keyerRead, keyerWrite ) ;
				
				//  check if device has WinKey
				if ( winkeyWrite <= 0 ) {
					[ winkeyButton setEnabled:NO ] ;
					[ winkeyMessage setEnabled:NO ] ;
				}

				//  create thread to listen to messages from the opened ports
				[ NSThread detachNewThreadSelector:@selector(pollThread) toTarget:self withObject:nil ] ;
				
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

- (void)stopPollingKeyer
{
	//  close one of the pipes to abort the polling thread (this releases one of the retain counts to allow dealloc)
	close( pttRead ) ;
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

- (void)pollThread
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	fd_set selectSet, readSet ;
	int fd, count, selectSetSize, type[FD_SETSIZE] ;
	unsigned char tempBuffer[32] ;

	//  First initialize fd_set and type array
	FD_ZERO( &selectSet ) ;
	selectSetSize = 0 ;
	bzero( type, FD_SETSIZE*sizeof( int ) ) ;

	//  Now set up the select set to listen to CW(flags), PTT(flags), RADIO, WINKEY and CONTROL channels
	//setSelectInfo( cwRead, &selectSet, CWPORT, type, &selectSetSize ) ;					//  v1.30 changed to write-only
	//setSelectInfo( pttRead, &selectSet, PTTPORT, type, &selectSetSize ) ;					//  v1.30 changed to write-only
	setSelectInfo( radioRead, &selectSet, RADIOPORT, type, &selectSetSize ) ;
	//setSelectInfo( winkeyRead, &selectSet, WINKEYPORT, type, &selectSetSize ) ;			//  v1.30 changed to write-only
	//setSelectInfo( controlRead, &selectSet, CONTROLPORT, type, &selectSetSize ) ;			//  v1.30 changed to write-only
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
						//  NOTE: v1.30  these show now be write-only ports
						//  Nothing to do, just flush the pipe by reading as much data as we can from the fd
						//  Most often, this is just the two byte ARE_YOU_THERE response from the keyer's control channel
						count = read( fd, tempBuffer, 32 ) ;
						break ;
					case RADIOPORT:
						//  read a byte at a time from radio port.  
						//  select() will keep calling us until done
						count = read( fd, tempBuffer, 1 ) ;
						if ( count > 0 ) [ self handleRadioData:tempBuffer[0] ] ;
						break ;
					default:
						//  should not get here, just flush the data
						read( fd, tempBuffer, 32 ) ;
					}
				}
			}
		}
	}
	[ pool release ] ;
}

- (void)setK3MainVFOString:(NSString*)string
{
	[ k3MainVFO setStringValue:string ] ;
}

- (void)setK3SubVFOString:(NSString*)string
{
	[ k3SubVFO setStringValue:string ] ;
}

- (void)setMainVFOString:(NSString*)string
{
	[ mainVFO setStringValue:string ] ;
}

- (void)setSubVFOString:(NSString*)string
{
	[ subVFO setStringValue:string ] ;
}

//  RADIO data sent from the Router
- (void)handleRadioData:(int)data
{
	int MHz, kHz, fraction ;
	NSString *str ;
	
	if ( parseK3VFO ) {
		k3String[ radioParserSequence ] = data ;
		if ( radioParserSequence > 20 ) {
			parseK3VFO = NO ;
			return ;
		}
		if ( data == ';' ) {
			k3String[ radioParserSequence+1 ] = 0 ;
			radioParserSequence = 0 ;
			sscanf( &k3String[2], "%5d%3d%2d", &MHz, &kHz, &fraction ) ;
			if ( k3String[0] == 'F' ) {
				str = [ NSString stringWithFormat:@"%02d.%03d.%2d", MHz, kHz, fraction ] ;
				if ( k3String[1] == 'A' ) {
					[ self performSelectorOnMainThread:@selector(setK3MainVFOString:) withObject:str waitUntilDone:NO ] ;
				}
				else if ( k3String[1] == 'B' ) {
					[ self performSelectorOnMainThread:@selector(setK3SubVFOString:) withObject:str waitUntilDone:NO ] ;
				}
			}
			return ;
		}
		radioParserSequence++ ;
		return ;
	}
	
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
			fraction = encodedVFO / 16.0 ;
		case 21:
			//  main/sub VFO frequency received
			
			fraction = encodedVFO / 16.0 ;
			kHz = fraction/100 ;
			fraction -= kHz*100 ;
			MHz = kHz/1000 ;
			kHz -= MHz*1000 ;
			str = [ NSString stringWithFormat:@"%02d.%03d.%2d", MHz, kHz, fraction ] ;
			if ( radioParserSequence == 5 ) 
				[ self performSelectorOnMainThread:@selector(setMainVFOString:) withObject:str waitUntilDone:NO ] ;
			else 
				[ self performSelectorOnMainThread:@selector(setSubVFOString:) withObject:str waitUntilDone:NO ] ;
			break ;
		case 31:
			// turn off VFO parser and unlock the radio
			parseVFO = NO ;
			//[ radioBusy unlockWithCondition:kHasData ] ;
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
	const char *string ;
	unsigned char output[32], *s ;
	int length ;
	
	string = [ [ winkeyMessage stringValue ] cString ] ;
	length = strlen( string ) ;
	
	if ( length <= 0 ) return ;
	
	s = output ;
	
	while ( *string ) {
		switch ( *string ) {
		case '[':
			*s++ = 0x1b ;		// winkey's merge command
			break ;
		case ']':
			break ;
		default:
			*s++ = *string ;
		}
		string++ ;
	}
	*s = 0 ; // v 1.50
	
	length = strlen( (char*)output ) ;	
	if ( winkeyWrite ) write( winkeyWrite, output, length ) ;
}

- (void)sendFSK:(id)sender
{
	const char *string ;
	int length ;
	
	string = [ [ fskMessage stringValue ] cString ] ;
	length = strlen( string ) ;
	
	if ( length <= 0 ) return ;
	
	if ( fskWrite ) write( fskWrite, string, length ) ;
}

// ------- K3 ---------------
//  v1.62
- (void)k3SetRadioParams
{
	int baudrateConst ;
	unsigned char command[] = { 0x01, 0x00, 0x00, 0x00, 0x81 } ;
	
	baudrateConst = 11059200/4800 ;				// 4,800 baud
	command[1] = baudrateConst & 0xff ;
	command[2] = baudrateConst/256 ;
	command[3] = 0x60 ;							// 8 bits, 1 stop, no parity
	
	write( controlWrite, command, 5 ) ;	
	usleep( 50000 ) ;							//  sleep for 50 ms after setting up radio channel in the keyer
	radioParamsSet = YES ;
}

//  select LSB, USB, CW, RTTY, PKT modes from NSMatrix and change FT-1000MP mode
//  v1.62
- (void)k3ChangeRadioMode:(id)sender
{
	unsigned char command[] = "MD1;" ;
	int row, mode[] = { '1', '2', '3', '6', '6' } ;

	if ( !radioParamsSet ) [ self k3SetRadioParams ] ;
	
	row = [ sender selectedRow ] ;
	command[2] = mode[row] ;
	
	write( radioWrite, command, 4 ) ;	
	if ( row == 3 ) write( radioWrite, "DT0;", 4 ) ;
	if ( row == 4 ) write( radioWrite, "DT2;", 4 ) ;
}

//  fetch VFO frequency from K3
- (void)k3TimedUpdateVFO:(NSTimer*)sender
{
	if ( !radioParamsSet ) [ self k3SetRadioParams ] ;
	
	int i ;
	for ( i = 0; i < 2; i++ ) {
		if ( [ radioBusy tryLock ] ) {
			//  don't send VFO request if we are not in the middle of waiting for something from the radio
			parseK3VFO = YES ;
			radioParserSequence = 0 ;
			write( radioWrite, "fa;fb;", 6 ) ;
			[ radioBusy unlock ] ;
			break ;
		}
	}
}

- (void)k3UpdateVFO:(id)sender
{
	if ( looping ) {
		[ looping invalidate ] ;
		looping = nil ;
		return ;
	}
	looping = [ NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(k3TimedUpdateVFO:) userInfo:self repeats:YES ] ;
}


// ------- FT-1000MP ---------------

- (void)setRadioParams
{
	int baudrateConst ;
	unsigned char command[] = { 0x01, 0x00, 0x00, 0x00, 0x81 } ;
	
	baudrateConst = 11059200/4800 ;				// 4,800 baud
	command[1] = baudrateConst & 0xff ;
	command[2] = baudrateConst/256 ;
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
- (void)timedUpdateVFO:(NSTimer*)sender
{
	unsigned char command[] = { 0x00, 0x00, 0x00, 0x03, 0x10 } ;

	if ( !radioParamsSet ) [ self setRadioParams ] ;
	
	int i ;
	for ( i = 0; i < 2; i++ ) {
		if ( [ radioBusy tryLock ] ) {
			//  don't send VFO request if we are not in the middle of waiting for something from the radio
			parseVFO = YES ;
			radioParserSequence = 0 ;
			write( radioWrite, command, 5 ) ;
			[ radioBusy unlock ] ;
			break ;
		}
	}
}

- (void)updateVFO:(id)sender
{
	if ( looping ) {
		[ looping invalidate ] ;
		looping = nil ;
		return ;
	}
	looping = [ NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timedUpdateVFO:) userInfo:self repeats:YES ] ;
}


@end

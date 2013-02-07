//
//  WinKeyEmulator.m
//  µH Router
//
//  Created by Kok Chen on 7/3/06.
	#include "Copyright.h"
	

#import "WinKeyEmulator.h"

@implementation WinKeyEmulator

- (id)initWithRouter:(Router*)client
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		router = client ;
		for ( i = 0; i < 256; i++ ) {
			ascii[i] = "" ;
			immediateCommand[i] = NO ;
		}
		ascii[' '] = " " ;		// one unit pause fillowed by inter cgaracter pause (3 units)
		ascii['a'] = ".-" ;
		ascii['b'] = "-..." ;
		ascii['c'] = "-.-." ;
		ascii['d'] = "-.." ;
		ascii['e'] = "." ;
		ascii['f'] = "..-." ;
		ascii['g'] = "--." ;
		ascii['h'] = "...." ;
		ascii['i'] = ".." ;
		ascii['j'] = ".---" ;
		ascii['k'] = "-.-" ;
		ascii['l'] = ".-.." ;
		ascii['m'] = "--" ;
		ascii['n'] = "-." ;
		ascii['o'] = "---" ;
		ascii['p'] = ".--." ;
		ascii['q'] = "--.-" ;
		ascii['r'] = ".-." ;
		ascii['s'] = "..." ;
		ascii['t'] = "-" ;
		ascii['u'] = "..-" ;
		ascii['v'] = "...-" ;
		ascii['w'] = ".--" ;
		ascii['x'] = "-..-" ;
		ascii['y'] = "-.--" ;
		ascii['z'] = "--.." ;
		for ( i = 'a'; i <= 'z'; i++ ) ascii[i-'a'+'A'] = ascii[i] ;
		ascii['0'] = "-----" ;
		ascii['1'] = ".----" ;
		ascii['2'] = "..---" ;
		ascii['3'] = "...--" ;
		ascii['4'] = "....-" ;
		ascii['5'] = "....." ;
		ascii['6'] = "-...." ;
		ascii['7'] = "--..." ;
		ascii['8'] = "---.." ;
		ascii['9'] = "----." ;

		ascii['.'] = ".-.-.-" ;
		ascii[','] = "--..--" ;
		ascii['?'] = "..--.." ;
		ascii[0x22] = ".-..-." ;
		ascii['#'] = ascii['%'] = ascii['&'] = ascii['*'] = ".." ;
		ascii['$'] = "...-..-" ;
		ascii[0x27] = ".----." ;
		ascii['('] = "-.--." ;
		ascii[')'] = "-.--.-" ;
		ascii['+'] = ".-.-." ;
		ascii['-'] = "-....-" ;
		ascii['/'] = "-..-." ;
		ascii[':'] = "-.--." ;
		ascii[';'] = ".-.-" ;
		ascii['<'] = ".-.-." ;
		ascii['='] = "-...-" ;
		ascii['>'] = "...-.-" ;
		ascii['@'] = ".--.-." ;
		
		immediateCommand[0] = YES ;
		immediateCommand[1] = YES ;
		immediateCommand[2] = YES ;
		immediateCommand[3] = YES ;
		immediateCommand[6] = YES ;
		immediateCommand[0xb] = YES ;
		immediateCommand[0xc] = YES ;
		immediateCommand[0xd] = YES ;
		immediateCommand[0xe] = YES ;
		immediateCommand[0x10] = YES ;
		immediateCommand[0x11] = YES ;
		immediateCommand[0x12] = YES ;
		immediateCommand[0x14] = YES ;
		immediateCommand[0x16] = YES ;
		
		[ self reset ] ;
		immediate = 0 ;
		
		//  create pipe to high priority thread
		unlink( "/tmp/winkeyemulator" ) ;
		//  now create the named pipe
		if ( mknod( "/tmp/winkeyemulator", S_IFIFO | 0600, 0 ) == 0 ) {
			fd = open( "/tmp/winkeyemulator", O_RDWR ) ;
			[ NSThread detachNewThreadSelector:@selector(loop:) toTarget:self withObject:self ] ;
		}
	}
	return self ;
}

- (void)reset
{
	extension = keyComp = 0 ;
	weight = 0.5 ;
	wpm = farns = 25 ;
	ratio = 3.0 ;
	[ self setSpeed ] ;
	pause = NO ;
	mergeLetters = NO ;
}


//	note: 0.24 seconds per element at 5 wpm
//	PARIS = 1 word = 50 elements
- (void)setSpeed
{
	float t, tw ;
	
	if ( farns < wpm ) farns = wpm ;

	t = 0.240*5.0/farns ;
	tw = 0.240*5.0/wpm ;
	
	dit = 2*t*weight ;
	dash = (ratio-1)*t + dit ;
	interElement = 2*t*(1-weight) ;	
	interCharacter = 7*tw - 5*t ;
}

- (void)sendWinkey:(int)byte
{
	char buf[256] ;
	
	byte &= 0xff ;
	
	//  immediate commands are handled here
	if ( immediate != 0 ) {
		switch ( immediate ) {
		case 0:		// Admin
			switch ( byte ) {
			case 1:
				[ self reset ] ;
				break ;
			}
			break ;
		case 2:		// WPM frequency
			wpm = byte ;
			if ( wpm == 0 ) wpm = 18 ;
			farns = wpm ;
			[ self setSpeed ] ;
			break ;
		case 3:		// weight
			if ( byte < 10 ) byte = 10 ; else if ( byte > 90 ) byte = 90 ;
			weight = byte/100.0 ;
			[ self setSpeed ] ;
			break ;
		case 6:			//  Pause
			pause = ( byte == 1 ) ;
			break ;
		case 0xb:		//  Key Immediate
			[ router sendSerialCW:( byte == 1 ) ] ;
			break ;
		case 0xd:		// Set Farns WPM
			farns = byte ;
			if ( farns < 10 ) farns = 10 ; else if ( farns > 99 ) farns = 99 ;
			[ self setSpeed ] ;
			break ;
		case 0x10:		// Set 1st Extension
			if ( byte > 250 ) byte = 250 ;
			extension = byte/1000.0 ;
			break ;
		case 0x11:		// Set Key Comp
			if ( byte > 250 ) byte = 250 ;
			extension = byte/1000.0 ;
			break ;
		case 0x17:		// Set Dit Dah Ratio
			if ( byte < 33 ) byte = 33 ; else if ( byte > 66 ) byte = 66 ;
			ratio = 3.0*byte/50.0 ;
			break ;
		case 1:			// sidetone frequency
		case 0xc:		// Set HSCW
		case 0xe:		// Set WinKey Mode
		case 0x12:		// Set Paddle Switchpoint
		case 0x14:		// Software Paddle
		case 0x16:		// Pointer Command
			//  do nothing
			break ;
		}
		immediate = 0 ;
		return ;
	}
	
	if ( immediateCommand[byte] ) {
		immediate = byte ;
		return ;
	}
	if ( byte == 0x0a ) {
		//  clear buffer
		read( fd, buf, 256 ) ;
		[ router sendSerialCW:NO ] ;
		return ;
	}
	if ( byte == 7 || byte == 8 || byte == 0x13 || byte == 0x15 ) return ;

	buf[0] = byte ;
	write( fd, buf, 1 ) ;
}

- (void)sendCharacter:(char*)s merge:(Boolean)merge
{
	int v ;
	float u ;
	Boolean first ;
	if ( pause ) return ;
	
	first = YES ;
	while ( *s ) {
		v = *s++ ;
		if ( v == '.' ) {
			[ router sendSerialCW:YES ] ;
			u = dit + keyComp ;
			if ( first ) u += extension ;
			[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:u ] ] ;
		}
		else {
			if ( v == '-' ) {
				[ router sendSerialCW:YES ] ;
				u = dash + keyComp ;
				if ( first ) u += extension ;
				[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:u ] ] ;
			}
			else if ( v == ' ' ) {
				[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:dit*2 ] ] ;
			}
		}
		first = NO ;
		[ router sendSerialCW:NO ] ;
		[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:interElement ] ] ;
	}
	if ( !merge ) [ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:interCharacter ] ] ;
}


- (void)loop:(id)sender
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	char *s, buf[1] ;
	int n, v ;
	
	[ NSThread setThreadPriority:1.0 ] ;
	while ( 1 ) {
		n = read( fd, buf, 1 ) ;
		if ( n <= 0 ) break ;
		v = buf[0] & 0xff ;
		
		switch ( v ) {
		case 9:		// Set PinConfig
		case 0x18:	// PTT On-off
		case 0x19:	// Key Buffered
		case 0x1a:	// Wait for nn seconds
			//  eat byte parameter
			read( fd, buf, 1 ) ;
			break ;
		case 4:		// PTT Lead In
			//  eat byte parameter
			for ( n = 0; n < 2; n++ ) read( fd, buf, 1 ) ;
			break ;
		case 5:		// Speed Pot
			//  eat byte parameters
			for ( n = 0; n < 3; n++ ) read( fd, buf, 1 ) ;
			break ;
		case 0xf:	// Speed Pot
			//  eat byte parameters
			for ( n = 0; n < 15; n++ ) read( fd, buf, 1 ) ;
			break ;
		case 0x1b:	// Merge Letters
			mergeLetters = YES ;
			break ;
		default:
			s = ascii[v] ;
			if ( *s != 0 ) [ self sendCharacter:s merge:mergeLetters ] ;
			mergeLetters = NO ;
			break ;
		}
	}
	[ pool release ] ;
}
@end

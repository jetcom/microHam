//
//  Server.h
//  µH Router
//
//  Created by Kok Chen on 5/23/06.

#ifndef _SERVER_H_
	#define _SERVER_H_
	
	#import <Cocoa/Cocoa.h>
	#include <sys/select.h>
	#include "NamedFIFOPair.h"

	@class Controller ;
	@class Router ;
	
	typedef struct {
		NamedFIFOPair *fifo ;			//  fifo that owns the fd
		int type ;						//	{ 0, kSelectServer } 
		int routerfd ;					//  the read file descriptor that was used to create this port
		NSDate *timestamp ;
		Boolean pending ;
		Boolean writeOnly ;				// v1.13
	} SelectInfo ;

	@interface Server : NSObject {
		//  select() sets
		fd_set selectSet ;
		SelectInfo readSelect[FD_SETSIZE] ;
		int radiofd[FD_SETSIZE] ;
		int controlfd[FD_SETSIZE] ;
		int pttfd[FD_SETSIZE] ;
		int cwfd[FD_SETSIZE] ;
		int rtsfd[FD_SETSIZE] ;
		int winkeyfd[FD_SETSIZE] ;
		int fskfd[FD_SETSIZE] ;
		int flagsfd[FD_SETSIZE] ;
		int portCount ;
		int actualSetSize ;
		int deferredClose ;					//  this makes sure that a CLOSEKEYER that arrives at select() as other commands gets executed last
	
		Boolean hasWinKey ;
		Boolean hasFSK ;
		
		Boolean debug ;
		Boolean logToConsole ;			//  v1.11
		
		Router *router ;
		NSString *baseName ;				// append with "Read" or "Write" to get fifo names
		NamedFIFOPair *backdoorFIFO ;
		int deviceType ;					// v1.11i
		
		unsigned char commandBuffer[32] ;
		NSLock *writeLock ;					// v1.11
		
		//  accumulate radio string v 1.11
		NSLock *radioDataLock ;
		int radioDataCount ;
		long totalRadioCount ;

		//  filter 78...f8 (voltage changes) packets
		int previous78Value ;
		int current78Index ;
		int bufferFor78Packet[8] ;
		//  filter heartbeats and LCD packets
		int filteredTail ;
		Boolean passHeartbeat, passLCD ;
		//  v1.11t
		float radioAggregateTimeout ;
		Boolean debugRadioPort ;
		int debugRadioPortCount ;
	}

	- (id)initWithName:(NSString*)mainfifo router:(Router*)control writeLock:(NSLock*)lock ;
	- (const char*)addClient ;
	
	- (void)setRadioAggregateTimeout:(float)value ;		//  v1.11t
	
	- (Boolean)hasWinKey ;
	- (void)setHasWinKey:(Boolean)state ;
	- (Boolean)hasFSK ;
	- (void)setHasFSK:(Boolean)state ;
	
	- (Boolean)inUse ;
 
	- (Boolean)debug ;
	- (void)setDebug:(Boolean)state ;
	- (void)setConsoleDebug:(Boolean)state ;
	
	//  control packet filtering
	- (void)passFilteredControl:(int)command ;

	//  support for select()
	- (void)quitKeyer ;
	- (void)closeAllConnectionsTo:(int)fd ;
	- (void)insertIntoSelectSet:(NamedFIFOPair*)fifo type:(int)type router:(int)routerfd writeOnly:(Boolean)writeOnly ;		//  v1.30
	- (void)removeFromSelectSet:(NamedFIFOPair*)fifo ;
	- (void)removeFromSelectSet:(int)closetype router:(int)routerfd ;
	
	//  handle requests from clients
	- (int)serverRequestReceived:(int)readfd ;
	- (void)setFlagUsing:(SEL)method from:(int)readfd ;
	- (void)setFlagValueUsing:(SEL)method from:(int)fd ;
	- (void)sendBytesUsing:(SEL)method from:(int)fd ;
	- (void)sendStringUsing:(SEL)method from:(int)fd ;
	
	//  handle replies from keyers
	- (void)receivedRadio:(int)data ;
	- (void)receivedControl:(int)data valid:(int)valid ;
	- (void)receivedWinKey:(int)data ;
	- (void)receivedFSK:(int)data ;
	- (void)receivedFlags:(int)data ;
	
	@end

	#define	MICROKEYER	0
	#define	CWKEYER		1
	#define	DIGIKEYER	2
	#define	DIGIKEYER2	3
	
#endif

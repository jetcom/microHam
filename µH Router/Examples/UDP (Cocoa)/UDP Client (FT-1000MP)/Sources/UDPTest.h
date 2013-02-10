//
//  UDPTest.h
//  UDP CLient
//
//  Created by Kok Chen on 3/13/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UDP.h"

@interface UDPTest : NSObject {
	int	mySocket ;									//  the UDP socket for us to send and receive data through
	struct sockaddr_in *myAddress ;					//  the UDP address for the above
	struct sockaddr_in *udpServerAddress ;			//  µH Router's main UDP address
	struct sockaddr_in *udpMicroKeyerAddress ;		//  microKeyer's UDP address in the µH Router
	struct sockaddr_in *udpDigiKeyerAddress ;		//  digiKeyer's UDP address in the µH Router
	struct sockaddr_in *udpCWKeyerAddress ;			//  CW Keyer's UDP address in the µH Router
}

@end

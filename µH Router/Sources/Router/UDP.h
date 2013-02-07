/*
 *  UDPSupport.h
 *  uH Router
 *
 *  Created by Kok Chen on 3/13/09.
 *  Copyright 2009 Kok Chen, W7AY. All rights reserved.
 *
 */

#include <stdio.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <string.h>
#include <unistd.h>
#import "RouterCommands.h"

//  command prefixes 
#define	RADIO_PREFIX		OPENRADIO			//  RADIO port
#define	CONTROL_PREFIX		OPENCONTROL			//  CONTROL port
#define	PTT_PREFIX			OPENPTT				//  PTT flag bit
#define	CW_PREFIX			OPENCW				//  serial CW flag bit
#define RTS_PREFIX			OPENRTS				//	RTS flag bit
#define	FSK_PREFIX			OPENFSK				//	FSK port
#define	WINKEY_PREFIX		OPENWINKEY			//	WinKey port
#define	FLAGS_PREFIX		OPENFLAGS			//  FLAGS port
#define	EMULATOR_PREFIX		OPENEMULATOR		//  WinKey Emulator port (only in µH Router; not in microHAM keyers)
#define WINDOW_PREFIX		WINDOWSIZE			//  <WINDOW_PREFIX> <RADIO_PREFIX> <n>; n==0 indefinite window


#define	LocalHost			"127.0.0.1"
#define	mHUDPServerPort		( ( 0x8000 | '  mH' ) & 0xffff )		//  60744



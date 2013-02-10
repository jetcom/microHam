/*
 *  RouterPort.h
 *  RouterTest
 *
 *  Created by Kok Chen on 5/25/06.
 */

void obtainRouterPorts( int *readFileDescriptor, int *writeFileDescriptor, int type, int parentReadFileDescriptor, int parentWriteFileDescriptor ) ;

void getKeyerID( int index, int parentReadFileDescriptor, int parentWriteFileDescriptor, char *kid ) ;

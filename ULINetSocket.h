//
//  ULINetSocket.h
//  Version 0.9
//
//  Copyright (c) 2001 Dustin Mierau.
//	With modifications by Uli Kusterer.
//
//	This software is provided 'as-is', without any express or implied
//	warranty. In no event will the authors be held liable for any damages
//	arising from the use of this software.
//
//	Permission is granted to anyone to use this software for any purpose,
//	including commercial applications, and to alter it and redistribute it
//	freely, subject to the following restrictions:
//
//	   1. The origin of this software must not be misrepresented; you must not
//	   claim that you wrote the original software. If you use this software
//	   in a product, an acknowledgment in the product documentation would be
//	   appreciated but is not required.
//
//	   2. Altered source versions must be plainly marked as such, and must not be
//	   misrepresented as being the original software.
//
//	   3. This notice may not be removed or altered from any source
//	   distribution.
//

/*!
 @header ULINetSocket.h
 An Objective-C class to simplify asynchronous networking.
 */

#import <Foundation/Foundation.h>
#import <netinet/in.h>

@interface ULINetSocket : NSObject 
{
	CFSocketRef				mCFSocketRef;
	CFRunLoopSourceRef		mCFSocketRunLoopSourceRef;
	id						mDelegate;
	NSTimer*				mConnectionTimer;
	BOOL					mSocketConnected;
	BOOL					mSocketListening;
	NSMutableData*			mOutgoingBuffer;
	NSMutableData*			mIncomingBuffer;
}

/*! @methodgroup Creation */

/*! Creates, opens and schedules a new socket. */
+(ULINetSocket*)	netsocket;
+(ULINetSocket*)	netsocketListeningOnRandomPort;

/*! Creates a new open socket listening for connections on the specified port.
 @param inPort	the port the socket will listen for connection on. */
+(ULINetSocket*)	netsocketListeningOnPort: (UInt16)inPort;

/*! Creates a new open socket connecting to the specified host on the specified port.
 @param inHostname	the name of the host the socket will attempt to connect to.
 @param inPort		the port number the socket will attempt to connect on. */
+(ULINetSocket*)	netsocketConnectedToHost: (NSString*)inHostname port: (UInt16)inPort;

// Delegate (id<ULINetSocketDelegate>)
-(id)		delegate;
-(void)		setDelegate: (id)inDelegate;

/*! @methodgroup Opening and Closing */
/*! Prepares the socket for activity. This should always be called before attempting to connect to a host or listen for connections.
 @result YES if preparing the socket was successful, NO otherwise. */
-(BOOL)		open;

/*! Closes the socket. If the socket is connected to a host, this call will disconnect from that host. You will need to call open again after calling close as this call basically kills the socket from performing any more activity. You should always call this method before attempting to connect to another host. */
-(void)		close;

/*! @methodgroup Runloop Scheduling */
-(BOOL)		scheduleOnCurrentRunLoop;
-(BOOL)		scheduleOnRunLoop: (NSRunLoop*)inRunLoop;

/*! @methodgroup Listening */
-(BOOL)		listenOnRandomPort;
/*! Starts the socket listening for connections on the specified port. This method will limit pending connections to 5.
 @result	YES if the socket is successfully put into a listening state, NO otherwise.
 @param	inPort is the port the socket will listen for connections on. */
-(BOOL)		listenOnPort: (UInt16)inPort;

/*! Starts the socket listening for connections on the specified port, limiting pending connection count to the specified amount.
 @result	YES if the socket is successfully put into a listening state, NO otherwise.
 @param inPort					the port the socket will listen for connections on.
 @param inMaxPendingConnections	the maximum number of pending connections that should be allowed before connections start being refused. */
-(BOOL)		listenOnPort: (UInt16)inPort maxPendingConnections: (int)inMaxPendingConnections;

/*! Starts the socket listening for connections on the specified path. This method will limit pending connections to the specified amount.
 @result YES if the socket is successfully put into a listening state, NO otherwise.
 @param	path is the name of the socket.
 @param inMaxPendingConnections	the maximum number of pending connections that should be allowed before connections start being refused. */
-(BOOL)		listenOnLocalSocketPath: (NSString *)path maxPendingConnections: (int)inMaxPendingConnections;

/*! @methodgroup Connecting */
/*! Attempts to connect the socket to the specified host on the specified port.
 @result	YES if the socket is successfully put into a connecting state, NO otherwise.
 @param inHostname	the name of the host the socket will attempt to connect to.
 @param inPort		the port number the socket will attempt to connect on. */
-(BOOL)		connectToHost: (NSString*)inHostname port: (UInt16)inPort;

/*! Attempts to connect the socket to the specified host on the specified port. If a positive timeout value is specified the socket will timeout if the connection process takes longer, which is in seconds.
 @result	YES if the socket is successfully put into a connecting state, NO otherwise.
 @param inHostname	the name of the host the socket will attempt to connect to.
 @param inPort		the port number the socket will attempt to connect on.
 @param inTimeout	the amount of time the socket has to establish a connection. */
-(BOOL)		connectToHost: (NSString*)inHostname port: (UInt16)inPort timeout: (NSTimeInterval)inTimeout;

/*! Attempts to connect the socket on the specified path.
 @result	YES if the socket is successfully put into a connecting state, NO otherwise.
 @param path	the path of the socket. */
-(BOOL)		connectToLocalSocketPath: (NSString *)path;

/*! @methodgroup Peeking */
/*! Allows you to look at the data NetSocket has ready for reading without actually advancing the current read position. Returns all of the available data that is ready for reading. */
-(NSData*)		peekData;

/*! @methodgroup Reading */
/*! Attempts to read the amount of data specified from the socket, placing it into the specified memory buffer.
 @result	the amount of data (in bytes) actually placed in the buffer, this will never be greater than the specified amount.
 @param inBuffer	the memory buffer read data will be placed into.
 @param inAmount	the desired number of bytes to read. */
-(unsigned)		read: (void*)inBuffer amount: (unsigned)inAmount;

/*! Reads all the available data from the socket. That data that is read is appended to the specified mutable data object. 
 @result	the amount of data read in bytes.
 @param inData	the mutable data object to which the read data will be appended. */
-(unsigned)		readOntoData: (NSMutableData*)inData;

/*! Attempts to read the amount of data specified from the socket. The data that is read is appended to the specified mutable data object.
 @result	the amount of data (in bytes) actually placed onto the mutable data object, this value will never be greater than the specified amount.
 @param inData	the mutable data object in which the read data will be appended to.
 @param inAmount	the number of bytes to read. */
-(unsigned)		readOntoData: (NSMutableData*)inData amount: (unsigned)inAmount;

/*! Attempts to read the amount of data specified from the socket. The data that is read is converted to a string using the specified string encoding and then appended to the specified mutable string object.
 @result the amount of data actually read, this value will never be greater than the specified amount.
 @param inString		the mutable string object in which the read data will be appended to.
 @param inEncoding	the string encoding to use when converting the data intoto a string.
 @param inAmount		the number of bytes to read. */
-(unsigned)		readOntoString: (NSMutableString*)inString encoding: (NSStringEncoding)inEncoding amount: (unsigned)inAmount;

/*! Reads all of the available data from the socket.
 @result	the read data in a new data object. */
-(NSData*)		readData;

/*! Attempts to read the amount of data specified (in bytes) from the socket.
 @result	a new data object containing the read data. You can determine how much was actually read from the socket by checking the length of the data object.
 @param inAmount	the number of bytes to read. */
-(NSData*)		readData: (unsigned)inAmount;

/*! Reads all of the available data from the socket. Returns the read data as a new string object using the specified string encoding.
 @param inEncoding is the string encoding to use when converting the data into a string. */
-(NSString*)	readString: (NSStringEncoding)inEncoding;

/*! Attempts to read the number of bytes specified from the socket.
 @result	the read data as a new string object using the specified string encoding. You can determine how much was actually read from the socket by checking the length of the string object.
 @param inEncoding	the string encoding to use when converting the data into a string.
 @param inAmount		the number of bytes to read. */
-(NSString*)	readString: (NSStringEncoding)inEncoding amount: (unsigned)inAmount;

/*! @methodgroup Writing */
/*! Attempts to write the specified amount of bytes onto the socket. In most cases this will be instant, but if you are sending a large amount of data, the data will be copied and sent progressively onto the socket.
 @param inBytes	the memory buffer to write onto the socket.
 @param inLength	the size of the memory buffer in bytes. */
-(void)			write: (const void*)inBytes length: (unsigned)inLength;

/*! Attempts to write the specified data object onto the socket. In most cases this will be instant, but if you are sending a large amount of data, the data will be copied and sent progressively onto the socket.
 @param inData	the data object to write onto the socket. */
-(void)			writeData: (NSData*)inData;

/*! Attempts to write the specified string object onto the socket using the specified encoding to convert the string into data form. In most cases sending this data will be instant, but if you are sending a large amount of data, the data will be copied and sent progressively onto the socket.
 @param inString		the string object to write onto the socket.
 @param inEncoding	the string encoding to use converting the string into data form. */
-(void)			writeString: (NSString*)inString encoding: (NSStringEncoding)inEncoding;

// Properties
/*! Returns the address the socket is connected to as a string object. */
-(NSString*)	remoteHost;

/*! Returns the port the socket is connected on. */
-(UInt16)		remotePort;
-(NSString*)	localHost;
-(UInt16)		localPort;
-(BOOL)			isConnected;
-(BOOL)			isListening;
-(unsigned)		incomingBufferLength;
-(unsigned)		outgoingBufferLength;

-(CFSocketNativeHandle)	nativeSocketHandle;

/*! Returns the underlying CFSocket object. It's probably not a good idea to play with this, but what the hell eh? */
-(CFSocketRef)			cfsocketRef;

// Convenience methods
+(void)			ignoreBrokenPipes;

/*! A utility method for turning an address structure into a human-readable dotted IP string.
 @param inAddress	the BSD address structure to be converted. */
+(NSString*)	stringWithSocketAddress: (struct in_addr*)inAddress;

@end

#pragma mark -

/*! @methodgroup Delegate methods */

@protocol ULINetSocketDelegate
@optional

/*! Called when the specified socket has established a connection with the host.
 @param inNetSocket	the notifying socket. */
-(void) netsocketConnected: (ULINetSocket*)inNetSocket;

/*! Called when the socket could not connect during the specified time interval. The socket is closed automatically, you will need to open it again to use it.
 @param inNetSocket	the notifying socket.
 @param inTimeout	the alloted timeout (in seconds). */
-(void)	netsocket: (ULINetSocket*)inNetSocket connectionTimedOut: (NSTimeInterval)inTimeout;

/*! Called when the specified socket has lost its connection with the host.
 @param inNetSocket	the notifying socket. */
-(void)	netsocketDisconnected: (ULINetSocket*)inNetSocket;

/*! Called when a listening socket has accepted a new connection. A newly created NetSocket is created based on this new connecting client.
 You need to schedule the given connection on a runloop to be able to use it.
 @param inNetSocket		the notifying socket (The listening socket).
 @param inNewNetSocket	the newly connected socket, abuse it. */
-(void)	netsocket: (ULINetSocket*)inNetSocket connectionAccepted: (ULINetSocket*)inNewNetSocket;

/*! Called when the socket has more data available of the specified amount.
 @param inNetSocket	the notifying socket.
 @param inAmount		the number of bytes of new data available on the socket. */
-(void)	netsocket: (ULINetSocket*)inNetSocket dataAvailable: (unsigned)inAmount;

/*! Called when all of the data has been sent onto the socket.
 @param inNetSocket	the notifying socket. */
-(void)	netsocketDataSent: (ULINetSocket*)inNetSocket;

@end
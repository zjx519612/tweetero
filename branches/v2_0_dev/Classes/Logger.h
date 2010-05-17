//
//  Logger.h
//
//  Created by Sergey Shkrabak on 10/16/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#ifdef TRACE
	#define YFLog(format, ...)		NSLog(format, ## __VA_ARGS__)
#else
	#define YFLog(format, ...)
#endif

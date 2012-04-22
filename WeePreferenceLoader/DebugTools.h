//
//  DebugTools.h
//
//  Created by Andrew Richardson on 12-04-08.
//  Copyright (c) 2012. All rights reserved.
//

#ifndef DebugTools_h
#define DebugTools_h

#ifdef DEBUG
#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define ULog(fmt, ...) { UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%s\n [Line %d] ", __PRETTY_FUNCTION__, __LINE__] message:[NSString stringWithFormat:fmt, ##__VA_ARGS__]  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] autorelease]; [alert show]; }

#define LOG_FN_CALL DLog(@"%@ was called", NSStringFromSelector(_cmd))
#define LOG_FN_CALL_FINISHED DLog(@"%@ has finished", NSStringFromSelector(_cmd))
#define LOG_LINE DLog(@"")
#define LOG_THREAD DLog(@"Main thread: %@", ([NSThread isMainThread] ? @"YES", @"NO"))
#define LOG_BACKTRACE DLog(@"Backtrace: %@", [NSThread callStackSymbols])
#else
#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define ULog(fmt, ...)

#define LOG_FN_CALL
#define LOG_FN_CALL_FINISHED
#define LOG_LINE
#define LOG_THREAD
#define LOG_BACKTRACE
#endif

#endif

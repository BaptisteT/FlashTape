/*
 *  FlashLogger.h
 *  Project : Wemoms
 *
 *  Description : Centralized log system
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/09/12
 *  Copyright (c) 2014-2015 Globalis. All rights reserved.
 *
 */

@import UIKit;
@import Foundation;

#define kFlashRunLogFolderName @"Logs/RunLogs"

#import <execinfo.h>
#import <libgen.h>
#import <libkern/OSAtomic.h>
#import <signal.h>
#import <sys/time.h>
#import <time.h>
#include <unistd.h>

#import "FlashLogger.h"


// constants
NSString *const kFlashLogAtomTypeKey = @"FlashLogAtomTypeKey";
NSString *const kFlashLogAtomTypeHTTPValue = @"HTTP";
NSString *const kFlashLogAtomTypeDeviceValue = @"DEVICE";
NSString *const kFlashLogAtomTypeNotificationValue = @"NOTI";
NSString *const kFlashLogAtomTypeApplicationValue  = @"APPL";
NSString *const kFlashLogAtomStartDateKey = @"FlashLogAtomStartDateKey";
NSString *const kFlashLogAtomMethodKey = @"FlashLogAtomMethodKey";
NSString *const kFlashLogAtomEndPointKey = @"FlashLogAtomEndPointKey";
NSString *const kFlashLogAtomMessageKey = @"FlashLogAtomMessageKey";
NSString *const kFlashLogAtomParametersKey = @"FlashLogAtomParametersKey";
NSString *const kFlashLogAtomAppStateKey = @"FlashLogAtomAppStateKey";
NSString *const kFlashLogAtomStatusKey = @"FlashLogAtomStatusKey";
NSString *const kFlashLogAtomDurationKey = @"FlashLogAtomDurationKey";
NSString *const kFlashLogAtomServerDurationKey = @"FlashLogAtomServerDurationKey";
NSString *const kFlashLogAtomServerMessageKey = @"FlashLogAtomServerMessageKey";



NSString *const kUncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
NSString *const kUncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString *const kUncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

static const NSInteger kUncaughtExceptionHandlerSkipAddressCount = 4;
static const NSInteger kUncaughtExceptionHandlerReportAddressCount = 5;

// colors
static NSString *const kFlashColorRed = @"#ff0000";
static NSString *const kFlashColorBlue1 = @"#eaf7fd";
static NSString *const kFlashColorBlue2 = @"#c9ebfb";
static NSString *const kFlashColorBlue3 = @"#94d9f4";
static NSString *const kFlashColorBlue4 = @"#40d5ff";
static NSString *const kFlashColorBlue5 = @"#40747a";

// globals
static volatile int32_t gUncaughtExceptionCount = 0;
static const int32_t kUncaughtExceptionMaximum = 10;


// FlashLogger private
@interface FlashLogger()

/* Called in exception handlings */
+ (NSArray *)_backtrace;

/* Excpetion handling set up */
- (void)_installExceptionHandlers;

/* Excpetion handling tear down */
- (void)_uninstallExceptionHandlers;

@end



@implementation FlashLogger


#pragma mark - Singleton
/* Singleton access */
+ (instancetype)defaultLogger
{
    __strong static FlashLogger *_logger = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        _logger = [[FlashLogger alloc] init];
    });
    return _logger;
}


#pragma mark - Life cycle
/* Designated initializer */
- (id)init
{
    self = [super init];
    if (self)
    {
        BOOL tmpBool;
        @autoreleasepool {
            _identifier = [[[NSBundle mainBundle] bundleIdentifier] copy];
            _deviceModel = [[[UIDevice currentDevice] model] copy];
            _deviceOS  = [[NSString alloc] initWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName],  [[UIDevice currentDevice] systemVersion]];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
            NSString *logDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:kFlashRunLogFolderName];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:logDirectory isDirectory:&tmpBool]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:logDirectory withIntermediateDirectories:YES attributes:nil error:nil];
            }
            _pathToRunLogFolder = [logDirectory copy];
            
            NSDate *nowTime = [NSDate date];
            _currentLogName = [[NSString alloc] initWithFormat:@"Run-Wemoms-%@.log",
                               [[[[nowTime description]  stringByReplacingOccurrencesOfString:@":" withString:@"-"] stringByReplacingOccurrencesOfString:@" " withString:@"-"] substringToIndex:[[nowTime description] length] -6]];
            
            _logAtoms = [[NSMutableDictionary alloc] init];
        }


//        [self _installExceptionHandlers];
    }

    return self;
}


#pragma mark - Exception handling
/* Exception handling set up */
- (void)_installExceptionHandlers
{
    NSSetUncaughtExceptionHandler(&HandleException);
	signal(SIGABRT, SignalHandler);
	signal(SIGILL, SignalHandler);
	signal(SIGSEGV, SignalHandler);
	signal(SIGFPE, SignalHandler);
	signal(SIGBUS, SignalHandler);
	signal(SIGPIPE, SignalHandler);
}

/* Exception handling tear down */
- (void)_uninstallExceptionHandlers
{
    NSSetUncaughtExceptionHandler(NULL);
	signal(SIGABRT, SIG_DFL);
	signal(SIGILL, SIG_DFL);
	signal(SIGSEGV, SIG_DFL);
	signal(SIGFPE, SIG_DFL);
	signal(SIGBUS, SIG_DFL);
	signal(SIGPIPE, SIG_DFL);
}


+ (NSArray *)_backtrace
{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);

    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (int i = kUncaughtExceptionHandlerSkipAddressCount; i < kUncaughtExceptionHandlerSkipAddressCount + kUncaughtExceptionHandlerReportAddressCount; ++i)
    {
	 	[backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }

    free(strs);
    
    return backtrace;
}

- (void)handleException:(NSException *)exception
{
//    [exception reason]
//    [[exception userInfo] objectForKey:kUncaughtExceptionHandlerAddressesKey]]

    [self _uninstallExceptionHandlers];

	if ([[exception name] isEqual:kUncaughtExceptionHandlerSignalExceptionName])
	{
		kill(getpid(), [[[exception userInfo] objectForKey:kUncaughtExceptionHandlerSignalKey] intValue]);
	}
	else
	{
		[exception raise];
	}
}

void HandleException(NSException *exception)
{
	int32_t exceptionCount = OSAtomicIncrement32(&gUncaughtExceptionCount);
	if (exceptionCount < kUncaughtExceptionMaximum)
	{
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];

        NSArray *callStack = [FlashLogger _backtrace];
        [userInfo setObject:callStack forKey:kUncaughtExceptionHandlerAddressesKey];

        [[FlashLogger defaultLogger] performSelectorOnMainThread:@selector(handleException:) withObject:[NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:userInfo] waitUntilDone:YES];
    }
}

void SignalHandler(int signal)
{
	int32_t exceptionCount = OSAtomicIncrement32(&gUncaughtExceptionCount);
	if (exceptionCount < kUncaughtExceptionMaximum)
	{
        NSArray *callStack = [FlashLogger _backtrace];

        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:signal] forKey:kUncaughtExceptionHandlerSignalKey];
        [userInfo setObject:callStack forKey:kUncaughtExceptionHandlerAddressesKey];

        [[FlashLogger defaultLogger] performSelectorOnMainThread:@selector(handleException:) withObject:[NSException exceptionWithName:kUncaughtExceptionHandlerSignalExceptionName reason:[NSString stringWithFormat:@"Signal %d was raised.", signal] userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:signal] forKey:kUncaughtExceptionHandlerSignalKey]] waitUntilDone:YES];
    }
}


#pragma mark - Log files
/* Provides back a list of saved logs : that is the one saved when kFlashLogOptionsRunLog is there */
- (NSArray *)savedLogNames
{
    NSError *tmpError;
    NSMutableArray *result = nil;
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_pathToRunLogFolder error:&tmpError];
    if(tmpError) return result;
    
    result = [NSMutableArray array];
    [dirContents enumerateObjectsUsingBlock:^(NSString *afileName, NSUInteger idx, BOOL *stop) {
        if ([afileName hasPrefix:@"Run-"]) {
            [result addObject:afileName];
        }
    }];
    return result;
}

/* Will remove all logs from the log folder (but keep the current one otherwise it would cause issues) */
- (void)deleteLogs
{
    NSError *tmpError;
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_pathToRunLogFolder error:&tmpError];
    if(tmpError) return;
    
    [dirContents enumerateObjectsUsingBlock:^(NSString *afileName, NSUInteger idx, BOOL *stop) {
        if ([afileName hasPrefix:@"Run-"] && (NO == [afileName isEqualToString:_currentLogName])) {
            NSError *anError;
            [[NSFileManager defaultManager] removeItemAtPath:[_pathToRunLogFolder stringByAppendingPathComponent:afileName] error:&anError];
        }
    }];
}

/* Provides back the full content of a log */
- (NSString *)contentOfLogWithName:(NSString *)logName
{
    NSError *tmpError;
    NSString *fullPath =[_pathToRunLogFolder stringByAppendingPathComponent:logName];
    return [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:&tmpError];
}


#pragma mark - Elements
/* Will create and store one atoms */
- (NSString *)logAtomWithData:(NSDictionary *)data forUUID:(NSString *)uuid
{
    if(NO == self.logAtomEnabled) return nil;
    
    id elementType = data[kFlashLogAtomTypeKey];

    if ([elementType isKindOfClass:[NSString class]]) //why this check this will always be a string
    {
        if (uuid == nil)
        {
            uuid = [[NSUUID UUID] UUIDString];
        }

        _logAtoms[uuid] = data;

        return uuid;
    }

    return nil;
}

/* Will return all atoms recorded in reverse timestamp */
- (NSArray *)allLogAtoms
{
    NSArray *tmpArrayUUID= [_logAtoms keysSortedByValueUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [obj2[kFlashLogAtomStartDateKey] compare:obj1[kFlashLogAtomStartDateKey]];
    }];
    NSMutableArray *result = [NSMutableArray array];
    [tmpArrayUUID enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [result addObject:[_logAtoms objectForKey:obj]];
    }];
    return result;
}

/* Will return an HTML representation of atoms */
- (NSString *)allAtomsHTMLRepresentation
{
    NSArray *elementCategories = @[
        @{@"key":kFlashLogAtomStartDateKey, @"label":@"Date", @"width":@140, @"alignment":@"left", @"padding":@8, },
        @{@"key":kFlashLogAtomTypeKey, @"label":@"Type", @"width":@80, @"alignment":@"center", },
        @{@"key":kFlashLogAtomStatusKey, @"label":@"Status", @"width":@30, @"alignment":@"center", },
        @{@"key":kFlashLogAtomEndPointKey, @"label":@"Status", @"width":@(100), @"alignment":@"left", },
        @{@"key":kFlashLogAtomParametersKey, @"label":@"Parameters", @"width":@120, @"alignment":@"center", },
        @{@"key":kFlashLogAtomDurationKey, @"label":@"Duration", @"width":@100, @"alignment":@"center", },
    ];


    NSMutableString *htmlString = [NSMutableString string];

    [htmlString appendString:@"<table cellspacing=\"0\" border=\"1\" style=\"table-layout:fixed;\">"];

    [htmlString appendString:@"<thead style=\"word-wrap:break-word;\"><tr style=\"background-color:black;color:white;font-size:12px;\"><table cellspacing=\"0\" border=\"1\" style=\"table-layout:fixed;\"><thead style=\"word-wrap:break-word;\"><tr style=\"background-color:black;color:white;font-size:12px;\">"];

    // header
    for (NSDictionary *cat in elementCategories)
    {
        [htmlString appendString:[NSString stringWithFormat:@"<th scope=\"col\" style=\"width:%dpx\">%@</th>", [cat[@"width"] intValue], cat[@"label"]]];
    }
    [htmlString appendString:@"</tr></thead>"];

    [htmlString appendString:@"<tbody style=\"word-wrap:break-word;font-size:10px;\">"];

    // elements
    NSArray *allElements = [self allLogAtoms];
    for (NSDictionary *element in allElements)
    {
        NSString *type = element[kFlashLogAtomTypeKey];

        NSString *color;
        if ([type isEqualToString:kFlashLogAtomTypeHTTPValue]) {
            int statusCode = (int)[element[kFlashLogAtomStatusKey] integerValue];
            if (statusCode >= 300 && statusCode < 600) {
                color = kFlashColorRed;
            }
            else {
                int requestTime = [element[kFlashLogAtomDurationKey] intValue];

                if (requestTime < 300){
                    color = kFlashColorBlue1;
                } else if (requestTime < 800) {
                    color = kFlashColorBlue2;
                } else if (requestTime < 1500){
                    color = kFlashColorBlue3;
                } else if (requestTime < 5000){
                    color = kFlashColorBlue4;
                } else {
                    color = kFlashColorBlue5;
                }
            }
        }
        else if ([type isEqualToString:kFlashLogAtomTypeDeviceValue])
        {
            color = @"#FFFFFF";
        }
        else if ([type isEqualToString:kFlashLogAtomTypeNotificationValue])
        {
            color = @"#FFFF00";
        }
        else if ([type isEqualToString:kFlashLogAtomTypeApplicationValue])
        {
            color = @"#FF99CC";
        }


        [htmlString appendString:[NSString stringWithFormat:@"<tr style=\"background-color:%@;\">", color]];

        for (NSDictionary *cat in elementCategories)
        {
            NSMutableString *style = [NSMutableString string];

            if (cat[@"alignment"])
            {
                [style appendFormat:@"text-align:%@;", cat[@"alignment"]];
            }
            if (cat[@"padding"])
            {
                [style appendFormat:@"padding-left:%dpx;", [cat[@"padding"] intValue]];
            }

            NSString *stringValue = @"-";
            id value = element[cat[@"key"]];
            if (value)
            {
                stringValue = [NSString stringWithFormat:@"%@", value];
            }
            [htmlString appendString:[NSString stringWithFormat:@"<td style=\"%@\">%@</td>", style, stringValue]];
        }
        [htmlString appendString:@"</tr>"];
    }

    [htmlString appendString:@"</tbody>"];


    [htmlString appendString:@"</table>"];

    return htmlString;
}


/* Log atoms catch events */
- (void)deleteAllLogAtoms
{
    [_logAtoms removeAllObjects];
}




#pragma mark - Main log function

void FlashLogInternal(BOOL doLog,const char *filename, unsigned int line, NSString *format, ...)
{
    if ([format length] <= 0)
        return;

    if(NO == doLog) return;
    
    va_list argp;
    NSString * str;
    char * filenameCopy = NULL;
    char * lastPathComponent = NULL;
    struct timeval tv;
    struct tm tm_value;
    
    if(nil == format) return;
    
    @autoreleasepool {
        va_start(argp, format);
        str = [[NSString alloc] initWithFormat:format arguments:argp];
        va_end(argp);
        
        
        //going through a FILE* allows later to indicate an other file than stderr
        static FILE * stderrFileStream = NULL;
        static FILE * logFileStream = NULL;
        if ( NULL == stderrFileStream )
            stderrFileStream = stderr;
        
        gettimeofday(&tv, NULL);
        localtime_r(&tv.tv_sec, &tm_value);
        if(filename && line) {
            fprintf(stderrFileStream, "%04u-%02u-%02u %02u:%02u:%02u.%03u ", tm_value.tm_year + 1900, tm_value.tm_mon + 1, tm_value.tm_mday, tm_value.tm_hour, tm_value.tm_min, tm_value.tm_sec, tv.tv_usec / 1000);
            fprintf(stderrFileStream, "[%s:%u] ", [[[NSProcessInfo processInfo] processName] UTF8String], [[NSProcessInfo processInfo] processIdentifier]);
            filenameCopy = strdup(filename);
            lastPathComponent = basename(filenameCopy);
            fprintf(stderrFileStream, "(%s:%u) ", lastPathComponent, line);
        }
        fprintf(stderrFileStream, "%s\n", [str UTF8String]);
        
        
        FlashLogOptions currentOptions = [FlashLogger defaultLogger].logOptions;
        if((currentOptions & kFlashLogOptionsRunLog) == kFlashLogOptionsRunLog) {
            if ( NULL == logFileStream ) {
                NSString *fullPath =[[FlashLogger defaultLogger].pathToRunLogFolder stringByAppendingPathComponent:[FlashLogger defaultLogger].currentLogName];
                logFileStream =fopen([fullPath UTF8String], "a");
                fprintf(logFileStream, "[%s:%u] ", [[[NSProcessInfo processInfo] processName] UTF8String], [[NSProcessInfo processInfo] processIdentifier]);
                fprintf(logFileStream, "%04u-%02u-%02u\n", tm_value.tm_year + 1900, tm_value.tm_mon + 1, tm_value.tm_mday);
                fprintf(logFileStream, "---------------------------------------\n");
            }
            if(logFileStream) {
                if(filename && line) {
                    fprintf(logFileStream, "[%02u:%02u:%02u.%03u]", tm_value.tm_hour, tm_value.tm_min, tm_value.tm_sec, tv.tv_usec / 1000);
                    fprintf(logFileStream, "[%s:%u]\n  ", lastPathComponent, line);
                }
                fprintf(logFileStream, "%s\n", [str UTF8String]);
                fflush(logFileStream);
            }
        }
        free(filenameCopy);
    }
}


#pragma mark - Report function

void FlashLogReport(NSString *format, ...)
{
    if ([format length] <= 0)
        return;

    @autoreleasepool
    {
        va_list argp;
        va_start(argp, format);
        NSString *str = [[NSString alloc] initWithFormat:format arguments:argp];
        va_end(argp);

        struct timeval tv;
        struct tm tm_value;
        gettimeofday(&tv, NULL);
        localtime_r(&tv.tv_sec, &tm_value);

        static FILE *logFileStream = NULL;
        if (logFileStream == NULL)
        {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
            NSString *logDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Reports"];

            if ([[NSFileManager defaultManager] fileExistsAtPath:logDirectory isDirectory:NULL] == NO)
            {
                [[NSFileManager defaultManager] createDirectoryAtPath:logDirectory withIntermediateDirectories:YES attributes:nil error:nil];
            }

            NSDate *nowTime = [NSDate date];

            NSString *logFilename = [[NSString alloc] initWithFormat:@"%@-%@.txt", [[[NSBundle mainBundle] bundleIdentifier] stringByReplacingOccurrencesOfString:@"." withString:@"-"], [[[[nowTime description] stringByReplacingOccurrencesOfString:@":" withString:@"_"] stringByReplacingOccurrencesOfString:@" " withString:@"-"] substringToIndex:[[nowTime description] length] - 6]];

            NSString *fullPath = [logDirectory stringByAppendingPathComponent:logFilename];

            logFileStream = fopen([fullPath UTF8String], "a");
            fprintf(logFileStream, "[FlashEngine] %04u-%02u-%02u Report\n", tm_value.tm_year + 1900, tm_value.tm_mon + 1, tm_value.tm_mday);
            fprintf(logFileStream, "-------------------------------------------------------------------------\n\n");
        }

        if (logFileStream)
        {
            fprintf(logFileStream, "%s\n", [str UTF8String]);
            fflush(logFileStream);
        }
    }
}


@end

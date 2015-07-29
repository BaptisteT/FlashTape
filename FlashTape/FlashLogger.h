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

@import Foundation;

__BEGIN_DECLS
/* Core logging function */
void FlashLogInternal(BOOL doLog,const char *filename, unsigned int line, NSString *format, ...);
__END_DECLS

#define FlashLog(doLog, ...) FlashLogInternal(doLog, __FILE__, __LINE__, __VA_ARGS__)

//Atom constants
extern NSString *const kFlashLogAtomTypeKey;      //@"HTTP", @"NOTI", @"APPL"
extern NSString *const kFlashLogAtomTypeHTTPValue;
extern NSString *const kFlashLogAtomTypeDeviceValue;
extern NSString *const kFlashLogAtomTypeNotificationValue;
extern NSString *const kFlashLogAtomTypeApplicationValue;
extern NSString *const kFlashLogAtomStartDateKey;
extern NSString *const kFlashLogAtomMethodKey;
extern NSString *const kFlashLogAtomEndPointKey;
extern NSString *const kFlashLogAtomMessageKey;       //Used instead of Message in APPL and NOTI
extern NSString *const kFlashLogAtomParametersKey;
extern NSString *const kFlashLogAtomAppStateKey;
extern NSString *const kFlashLogAtomStatusKey;
extern NSString *const kFlashLogAtomDurationKey;
extern NSString *const kFlashLogAtomServerDurationKey;
extern NSString *const kFlashLogAtomServerMessageKey;



// FlashLogOptions
typedef enum
{
    kFlashLogOptionsNone =  0,
    kFlashLogOptionsRunLog = 1 << 1, 	//If this option is used , log will be written to a file in addition to the console
    kFlashLogOptionsSendToTestFlight =  1 << 2,

} FlashLogOptions;


// FlashLogger
@interface FlashLogger : NSObject
{
    NSString *_identifier;
    NSString *_deviceModel;
    NSString *_deviceOS;

    NSString *_pathToRunLogFolder;
    NSString *_currentLogName;

    NSMutableDictionary *_logAtoms;
}

@property (nonatomic, assign) FlashLogOptions logOptions;
@property(nonatomic,strong) NSString         *pathToRunLogFolder;
@property(nonatomic,strong) NSString         *currentLogName;
@property(nonatomic,assign) BOOL         logAtomEnabled;


/* Singleton access */
+ (instancetype)defaultLogger;

/* Provides back a list of saved logs : that is the one saved when kFlashLogOptionsRunLog is there */
- (NSArray *)savedLogNames;

/* Will remove all logs from the log folder */
- (void)deleteLogs;

/* Provides back the full content of a log */
- (NSString *)contentOfLogWithName:(NSString *)logName;

/* Log atoms catch events */
- (NSArray *)allLogAtoms;

/* Returns and HTML representation of the atoms */
- (NSString *)allAtomsHTMLRepresentation;

/* Will create and store one atoms */
- (NSString *)logAtomWithData:(NSDictionary *)data forUUID:(NSString *)uuid;

/* Log atoms catch events */
- (void)deleteAllLogAtoms;

@end

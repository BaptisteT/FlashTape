//
//  AddressbookUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "AddressbookUtils.h"

@implementation AddressbookUtils

// "us" -> @["USA", 1];
+ (NSMutableDictionary *)getCountriesAndCallingCodesForLetterCodes
{
    NSMutableDictionary *letterCodeToCountryAndCallingCode = [[NSMutableDictionary alloc] init];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"PhoneCountries" ofType:@"txt"];
    NSData *stringData = [NSData dataWithContentsOfFile:filePath];
    NSString *data = nil;
    if (stringData != nil)
        data = [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
    
    if (data == nil)
        return nil;
    
    NSString *delimiter = @";";
    NSString *endOfLine = @"\n";
    
    NSInteger currentLocation = 0;
    while (true)
    {
        NSRange codeRange = [data rangeOfString:delimiter options:0 range:NSMakeRange(currentLocation, data.length - currentLocation)];
        if (codeRange.location == NSNotFound)
            break;
        
        int callingCode = [[data substringWithRange:NSMakeRange(currentLocation, codeRange.location - currentLocation)] intValue];
        
        NSRange idRange = [data rangeOfString:delimiter options:0 range:NSMakeRange(codeRange.location + 1, data.length - (codeRange.location + 1))];
        if (idRange.location == NSNotFound)
            break;
        
        NSString *letterCode = [[data substringWithRange:NSMakeRange(codeRange.location + 1, idRange.location - (codeRange.location + 1))] lowercaseString];
        
        NSRange nameRange = [data rangeOfString:endOfLine options:0 range:NSMakeRange(idRange.location + 1, data.length - (idRange.location + 1))];
        if (nameRange.location == NSNotFound)
            nameRange = NSMakeRange(data.length, INT_MAX);
        
        NSString *countryName = [data substringWithRange:NSMakeRange(idRange.location + 1, nameRange.location - (idRange.location + 1))];
        if ([countryName hasSuffix:@"\r"])
            countryName = [countryName substringToIndex:countryName.length - 1];
        
        [letterCodeToCountryAndCallingCode setValue:@[countryName, [[NSNumber alloc] initWithInt:callingCode]] forKey:letterCode];
        
        currentLocation = nameRange.location + nameRange.length;
        if (nameRange.length > 1)
            break;
    }
    
    return letterCodeToCountryAndCallingCode;
}

@end

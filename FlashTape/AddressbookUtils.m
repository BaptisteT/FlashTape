//
//  AddressbookUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"

#import "AddressbookUtils.h"

#define CONTACT_DICTIONNARY_PREF @"Contact Dictionnary Pref"

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

+ (NSMutableDictionary *)getFormattedPhoneNumbersFromAddressBook:(ABAddressBookRef)addressBook;
{
    NSMutableDictionary *addressBookFormattedContacts = [[NSMutableDictionary alloc] init];
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex peopleCount = CFArrayGetCount(people);
    NSString *defaultCountry = [phoneUtil countryCodeByCarrier];
    
    for (CFIndex i = 0 ; i < peopleCount; i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(people, i);
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        for (CFIndex j = 0; j < ABMultiValueGetCount(phoneNumbers); j++) {
            NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            NSError *aError = nil;
            NBPhoneNumber *nbPhoneNumber = [phoneUtil parse:phoneNumber defaultRegion:defaultCountry error:&aError];
            
            if (aError == nil && [phoneUtil isValidNumber:nbPhoneNumber]) {
                NSString *name = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
                if (!name || name.length == 0) {
                    name = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
                    if (!name || name.length == 0) {
                        name = @"?";
                    }
                }
                // Stock potential contact
                NSString *phoneNumber = [NSString stringWithFormat:@"+%u%llu", (unsigned int)nbPhoneNumber.countryCode, nbPhoneNumber.nationalNumber];
                [addressBookFormattedContacts setObject:name forKey:phoneNumber];
            }
        }
    }

    CFRelease(people);
    return addressBookFormattedContacts;
}

+ (void)saveContactDictionnary:(NSDictionary *)contactDictionnary
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:contactDictionnary forKey:CONTACT_DICTIONNARY_PREF];
    [prefs synchronize];
}

+ (NSDictionary *)getContactDictionnary
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:CONTACT_DICTIONNARY_PREF];
}

@end

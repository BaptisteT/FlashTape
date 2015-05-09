//
//  AddressbookUtils.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBookUI/AddressBookUI.h>
#import <AddressBook/AddressBook.h>

@interface AddressbookUtils : NSObject

+ (NSMutableDictionary *)getCountriesAndCallingCodesForLetterCodes;

+ (NSMutableDictionary *)getFormattedPhoneNumbersFromAddressBook:(ABAddressBookRef)addressBook;

+ (void)saveContactDictionnary:(NSDictionary *)contactDictionnary;

+ (NSDictionary *)getContactDictionnary;

@end

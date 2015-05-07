//
//  CountryCodeTableViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CoutryCodeTVCDelegate;

@interface CountryCodeTableViewController : UITableViewController

@property (strong, nonatomic) id<CoutryCodeTVCDelegate> delegate;

@end

@protocol CoutryCodeTVCDelegate <NSObject>

- (void)updateCountryName:(NSString *)countryName code:(NSNumber *)code letterCode:(NSString *)letterCode;

@end
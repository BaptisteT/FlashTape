//
//  UnlockEmojisViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 7/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <MessageUI/MessageUI.h>
#import <UIKit/UIKit.h>

#import "InviteContactTableViewCell.h"


@interface UnlockEmojisViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, InviteContactTVCDelegate, MFMessageComposeViewControllerDelegate >

@end

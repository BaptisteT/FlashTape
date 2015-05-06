//
//  VideoViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

@import UIKit;

#import "SCRecorder.h"

@interface VideoViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, SCRecorderDelegate, UITableViewDelegate, UITableViewDataSource>

@end

//
//  EntityViewController.h
//  NSIncrementalStoreInUse
//
//  Created by Andrey Gusev on 10/20/13.
//  Copyright (c) 2013 Andrey Gusev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDataEntity.h"

@interface EntityViewController : UITableViewController

@property (nonatomic,strong) BaseDataEntity *entity;

@end

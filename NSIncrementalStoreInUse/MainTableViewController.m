//
//  MainTableViewController.m
//  NSIncrementalStoreInUse
//
//  Created by Andrey Gusev on 10/11/13.
//  Copyright (c) 2013 Andrey Gusev. All rights reserved.
//

#import "MainTableViewController.h"
#import "ItemsViewController.h"


@interface MainTableViewController ()

@end

@implementation MainTableViewController


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [self performSegueWithIdentifier:@"PushItemsList" sender:indexPath];
    
}

//==============================================================================
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath *)sender {
    
    ItemsViewController *itemsVC = segue.destinationViewController;
    
    switch (sender.row) {
        case 0:
            itemsVC.entityName = @"CoreDataEntity";
            break;

        case 1:
            itemsVC.entityName = @"SQLiteDataEntity";
            break;
            
        case 2:
            itemsVC.entityName = @"BaseDataEntity";
            break;
            
        default:
            itemsVC.entityName = nil;
            break;
    }
}


@end

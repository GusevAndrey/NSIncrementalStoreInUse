//
//  RelatedEntitiesViewController.m
//  NSIncrementalStoreInUse
//
//  Created by Andrey Gusev on 10/20/13.
//  Copyright (c) 2013 Andrey Gusev. All rights reserved.
//

#import "RelatedEntitiesViewController.h"
#import "DescriptionCell.h"

@interface RelatedEntitiesViewController ()

@end

@implementation RelatedEntitiesViewController


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return self.relatedEntities.count > 0 ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.relatedEntities.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DescriptionCell *cell = (DescriptionCell *)[tableView dequeueReusableCellWithIdentifier:@"descriptionCell" forIndexPath:indexPath];
    
    // Configure the cell...
    id entity = [self.relatedEntities objectAtIndex:indexPath.row];
    cell.descriptionLabel.text = [entity description];
    
    return cell;
}

@end

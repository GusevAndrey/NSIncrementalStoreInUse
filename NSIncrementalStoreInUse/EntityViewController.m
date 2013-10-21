//
//  EntityViewController.m
//  NSIncrementalStoreInUse
//
//  Created by Andrey Gusev on 10/20/13.
//  Copyright (c) 2013 Andrey Gusev. All rights reserved.
//

#import "EntityViewController.h"
#import "RelatedEntitiesViewController.h"

#import "RelatedEntityProtocol.h"
#import "DescriptionCell.h"

@interface EntityViewController ()

@end

@implementation EntityViewController

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return self.entity ? 1 : 0;
}

//==============================================================================
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    NSInteger rowCount = self.entity ? 1 : 0;

    if ([self.entity hasRelatedEntities])
        rowCount++;
    
    if ([self.entity hasFetchedEntities])
        rowCount++;
    
    // Return the number of rows in the section.
    return rowCount;
}

//==============================================================================
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        return 100.0f;
    }
    else {
        return 65.0f;
    }
}

//==============================================================================
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) return NO;
                       else return YES;
    
}

//==============================================================================
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) return nil;
                       else return indexPath;
    
}

//==============================================================================
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    switch (indexPath.row) {
            
        case 0: {            
            DescriptionCell *descrCell = (DescriptionCell *)[tableView dequeueReusableCellWithIdentifier:@"descriptionCell" forIndexPath:indexPath];
            
            descrCell.descriptionLabel.text = self.entity.description;
            
            cell = descrCell;
        }
            break;
            
        case 1:
            
            //Если есть relatedEntities или row не последний...
            if ( [self.entity hasRelatedEntities] ||
                ([tableView numberOfRowsInSection:indexPath.section] > indexPath.row + 1)) {
                
                cell = [tableView dequeueReusableCellWithIdentifier:@"relatedEntitiesCell" forIndexPath:indexPath];
                
            }
            
            //Если последний row и нет relatedEntities, то это - fetchedEntities
            else {
                cell = [tableView dequeueReusableCellWithIdentifier:@"fetchedEntitiesCell" forIndexPath:indexPath];
                
                id <RelatedEntityProtocol> relatedEntity = [self.entity.getFetchedEntities lastObject];
                
                cell.detailTextLabel.text = [NSString stringWithFormat:@"EntityID: %@",relatedEntity.entityId];
            }
            
            break;

            
        case 2: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"fetchedEntitiesCell" forIndexPath:indexPath];
            
            id <RelatedEntityProtocol> relatedEntity = [self.entity.getFetchedEntities lastObject];
            
            cell.detailTextLabel.text = [NSString stringWithFormat:@"EntityID: %@",relatedEntity.entityId];
        }
            break;
            
        default:
            
            /* nothing */
            
            break;
    }
    
    return cell;
}


//==============================================================================
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self performSegueWithIdentifier:@"PushEntities" sender:indexPath];
    
}



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Navigation
////////////////////////////////////////////////////////////////////////////////

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath *)sender {
    
    RelatedEntitiesViewController *relatedEntityController = segue.destinationViewController;

    switch (sender.row) {
            
        case 1:
            
            //Если есть relatedEntities или row не последний...
            if ( [self.entity hasRelatedEntities] ||
                ([self.tableView numberOfRowsInSection:sender.section] > sender.row + 1)) {
                
                relatedEntityController.relatedEntities = [[self.entity getRelatedEntities] array];
                relatedEntityController.title = @"Related Entities";
            }
            
            //Если последний row и нет relatedEntities, то это - fetchedEntities
            else {
                relatedEntityController.relatedEntities = [self.entity getFetchedEntities];
                relatedEntityController.title = @"Fethed Property Entities";
            }
            
            break;
            
        case 2:
            relatedEntityController.relatedEntities = [self.entity getFetchedEntities];
            relatedEntityController.title = @"Fethed Property Entities";
            break;
            
        default:
            
            /* nothing */
            
            break;
    }
}

@end

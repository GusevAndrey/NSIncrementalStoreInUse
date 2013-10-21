//
//  ItemsViewController.m
//  NSIncrementalStoreInUse
//
//  Created by Andrey Gusev on 10/11/13.
//  Copyright (c) 2013 Andrey Gusev. All rights reserved.
//

#import "ItemsViewController.h"
#import "EntityViewController.h"
#import "AppDelegate.h"

#import "BaseDataEntity.h"

@interface ItemsViewController () {
    
    NSDateFormatter *_formatter;
    
}

@end

@implementation ItemsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self remakeFetchResultControllerWithEntity:self.entityName];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Accessors
////////////////////////////////////////////////////////////////////////////////

- (void)setEntityName:(NSString *)entityName {
    
    if ([_entityName isEqualToString:entityName]) return;
    
    _entityName = entityName;
 
    //Если вьюшка уже загружена - загружаем в неё данные. Иначе это будет произведено во ViewDidLoad
    if (self.isViewLoaded) {
        [self remakeFetchResultControllerWithEntity:entityName];
    }
}




////////////////////////////////////////////////////////////////////////////////
#pragma mark - Fetch Controller
////////////////////////////////////////////////////////////////////////////////

//Создание нового контролера для новой сущности
- (void) remakeFetchResultControllerWithEntity:(NSString *)entityName {
    
    if (!entityName) {
        self.fetchedResultsController = nil;
        return;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    
    //Сортируем объекты по дате создания (самый поздний сверху)
    NSSortDescriptor *sortByCreationDate = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortByCreationDate]];
    
    //Размер одной выборки
    [fetchRequest setFetchBatchSize:20];

    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:appDelegate.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITableView
////////////////////////////////////////////////////////////////////////////////

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateStyle:NSDateFormatterLongStyle];
    }
    
    
    UITableViewCell *itemCell = [tableView dequeueReusableCellWithIdentifier:@"ItemCell" forIndexPath:indexPath];

    BaseDataEntity *entityData = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    itemCell.textLabel.text = NSStringFromClass([entityData class]);
    itemCell.detailTextLabel.text = [_formatter stringFromDate:entityData.creationDate];
    
    return itemCell;
};

//==============================================================================
 // Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        BaseDataEntity *objectToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        [appDelegate.managedObjectContext deleteObject:objectToDelete];
        
        NSError *error = nil;
        if (![appDelegate.managedObjectContext save:&error]) {
            
            NSLog(@"ERROR: %@",error);
            
        }
    }
}


//==============================================================================
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UITableViewCell *)sender {
 
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    
    BaseDataEntity *selectedEntity = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    EntityViewController *entityController = segue.destinationViewController;
    entityController.entity = selectedEntity;
    entityController.title = NSStringFromClass(selectedEntity.class);
}

@end

//
//  CoreDataTableViewController.m
//
//  Created for Stanford CS193p Fall 2011.
//  Copyright 2011 Stanford University. All rights reserved.
//

#import "CoreDataTableViewController.h"

@interface CoreDataTableViewController(){
    id _savedSelection;
}

@property (nonatomic) BOOL beganUpdates;

@end

@implementation CoreDataTableViewController

////////////////////////////////////////////////////////
#pragma mark - Properties
////////////////////////////////////////////////////////

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize suspendAutomaticTrackingOfChangesInManagedObjectContext = _suspendAutomaticTrackingOfChangesInManagedObjectContext;
@synthesize debug = _debug;
@synthesize beganUpdates = _beganUpdates;


- (void) dealloc {
    self.fetchedResultsController.delegate=nil;
    self.fetchedResultsController = nil;
}

////////////////////////////////////////////////////////
#pragma mark - Fetching
////////////////////////////////////////////////////////

- (void)performFetch
{
    if (self.fetchedResultsController) {
        if (self.fetchedResultsController.fetchRequest.predicate) {
            if (self.debug) NSLog(@"[%@ %@] fetching %@ with predicate: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsController.fetchRequest.entityName, self.fetchedResultsController.fetchRequest.predicate);
        } else {
            if (self.debug) NSLog(@"[%@ %@] fetching all %@ (i.e., no predicate)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsController.fetchRequest.entityName);
        }
        NSError *error = nil;
        [self.fetchedResultsController performFetch:&error];
        if (error) NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
    } else {
        if (self.debug) NSLog(@"[%@ %@] no NSFetchedResultsController (yet?)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    }
    [self.tableView reloadData];
}

- (void)setFetchedResultsController:(NSFetchedResultsController *)newfrc
{
    NSFetchedResultsController *oldfrc = _fetchedResultsController;
    if (newfrc != oldfrc) {
        oldfrc.delegate = nil;
        _fetchedResultsController = newfrc;
        newfrc.delegate = self;
        if ((!self.title || [self.title isEqualToString:oldfrc.fetchRequest.entity.name]) && (!self.navigationController || !self.navigationItem.title)) {
            self.title = newfrc.fetchRequest.entity.name;
        }
        if (newfrc) {
            if (self.debug) NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), oldfrc ? @"updated" : @"set");
            [self performFetch]; 
        } else {
            if (self.debug) NSLog(@"[%@ %@] reset to nil", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
            [self.tableView reloadData];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [[[self.fetchedResultsController sections] objectAtIndex:section] name];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        [self.tableView beginUpdates];
        self.beganUpdates = YES;
        // Save the current selection
        _savedSelection = [self selectedObjectInController:controller];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex
	 forChangeType:(NSFetchedResultsChangeType)type
{
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext)
    {
        switch(type)
        {
            case NSFetchedResultsChangeInsert:
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:[self animationForSectionInsert]];
                break;
                
            case NSFetchedResultsChangeDelete:
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:[self animationForSectionDelete]];
                break;
        }
    }
}

//==============================================================================
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath
	 forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath
{		
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext)
    {
        switch(type)
        {
            case NSFetchedResultsChangeInsert:
                [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:[self animationForRowInsert]];
                break;
                
            case NSFetchedResultsChangeDelete:
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:[self animationForRowDelete]];
                break;
                
            case NSFetchedResultsChangeUpdate:
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:[self animationForRowUpdate]];
                break;
                
            case NSFetchedResultsChangeMove:
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:[self animationForRowMoveDelete]];
                [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:[self animationForRowMoveInsert]];
                break;
        }
    }
}

//==============================================================================
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (self.beganUpdates) {
        [self.tableView endUpdates];
        NSIndexPath *indexPath = [self indexPathForObject:_savedSelection inController:controller];
        if(indexPath){
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO 
                                  scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Support methods
////////////////////////////////////////////////////////////////////////////////

-(UITableViewRowAnimation) animationForSectionInsert{
    return UITableViewRowAnimationLeft;
}

-(UITableViewRowAnimation) animationForSectionDelete{
    return UITableViewRowAnimationRight;
}

//==============================================================================

-(UITableViewRowAnimation) animationForRowInsert{
    return UITableViewRowAnimationTop;
}
-(UITableViewRowAnimation) animationForRowDelete{
    return UITableViewRowAnimationAutomatic;
}
-(UITableViewRowAnimation) animationForRowUpdate{
    return UITableViewRowAnimationAutomatic;
}
-(UITableViewRowAnimation) animationForRowMoveDelete{
    return UITableViewRowAnimationAutomatic;
}
-(UITableViewRowAnimation) animationForRowMoveInsert{
    return UITableViewRowAnimationAutomatic;
}


//==============================================================================
- (id)selectedObjectInController:(NSFetchedResultsController *)controller {
    return [controller objectAtIndexPath:self.tableView.indexPathForSelectedRow];
}

//==============================================================================
- (NSIndexPath *)indexPathForObject:(id)anObject inController:(NSFetchedResultsController *)controller {
    return [controller indexPathForObject:anObject];
}




//==============================================================================
- (void)endSuspensionOfUpdatesDueToContextChanges
{
    _suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
}

//==============================================================================
- (void)setSuspendAutomaticTrackingOfChangesInManagedObjectContext:(BOOL)suspend
{
    if (suspend) {
        _suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;
    } else {
        [self performSelector:@selector(endSuspensionOfUpdatesDueToContextChanges) withObject:0 afterDelay:0];
    }
}

@end


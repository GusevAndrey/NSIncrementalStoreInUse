//
//  SQLiteDataEntity.m
//  NSIncrementalStoreInUse
//
//  Created by Andrey Gusev on 10/18/13.
//  Copyright (c) 2013 Andrey Gusev. All rights reserved.
//

#import "SQLiteDataEntity.h"
#import "SQLiteRelatedEntity.h"

@interface SQLiteDataEntity () {
    
    NSDateFormatter *_formatter;
}
@end;

@implementation SQLiteDataEntity

@dynamic coreDataRelatedEntityID;
@dynamic relatedEntities;

@dynamic coreDataRelatedEntities;

- (NSOrderedSet *) getRelatedEntities {
    return self.relatedEntities;
}

//==============================================================================
- (NSArray *) getFetchedEntities {
    return self.coreDataRelatedEntities;
}

//==============================================================================
- (NSString *)description {
    
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateStyle:NSDateFormatterLongStyle];
    }
    
    NSMutableString *descr = [NSMutableString stringWithFormat:@"Name:                    %@\n",self.entity.name];
    
    [descr appendFormat:@"CreationDate:            %@\n",[_formatter stringFromDate:self.creationDate]];
    [descr appendFormat:@"CoreDataRelatedEntityID: %@\n",self.coreDataRelatedEntityID];
    
    return descr;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Support Mehtods
////////////////////////////////////////////////////////////////////////////////

- (BOOL) hasRelatedEntities {
    
    return self.relatedEntities.count > 0 ? YES : NO;
    
}

//==============================================================================
- (BOOL) hasFetchedEntities {
    
    [self.managedObjectContext refreshObject:self mergeChanges:YES];    
    return self.coreDataRelatedEntities.count > 0 ? YES : NO;
    
}

@end

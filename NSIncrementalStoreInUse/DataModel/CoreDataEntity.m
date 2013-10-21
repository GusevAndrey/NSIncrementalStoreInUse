//
//  CoreDataEntity.m
//  NSIncrementalStoreInUse
//
//  Created by Andrey Gusev on 10/18/13.
//  Copyright (c) 2013 Andrey Gusev. All rights reserved.
//

#import "CoreDataEntity.h"
#import "CoreDataRelatedEntity.h"

@interface CoreDataEntity () {
    
    NSDateFormatter *_formatter;
}

@end


@implementation CoreDataEntity

@dynamic relatedSQLEntityID;
@dynamic relatedEntities;

@dynamic sqliteRelatedEntities;


- (NSOrderedSet *) getRelatedEntities {
    return self.relatedEntities;
}

//==============================================================================
- (NSArray *) getFetchedEntities {
    return self.sqliteRelatedEntities;
}

//==============================================================================
- (NSString *)description {
    
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateStyle:NSDateFormatterLongStyle];
    }
    
    NSMutableString *descr = [NSMutableString stringWithFormat:@"Name:               %@\n",self.entity.name];

    [descr appendFormat:@"CreationDate:       %@\n",[_formatter stringFromDate:self.creationDate]];
    [descr appendFormat:@"SQLRelatedEntityID: %@\n",self.relatedSQLEntityID];
        
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
    return self.sqliteRelatedEntities.count > 0 ? YES : NO;
    
}


@end

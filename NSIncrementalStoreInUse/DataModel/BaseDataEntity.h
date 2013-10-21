//
//  BaseDataEntity.h
//  NSIncrementalStoreInUse
//
//  Created by Andrey Gusev on 10/18/13.
//  Copyright (c) 2013 Andrey Gusev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface BaseDataEntity : NSManagedObject

@property (nonatomic, retain) NSDate * creationDate;

- (NSOrderedSet *) getRelatedEntities;
- (NSArray *) getFetchedEntities;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Support Mehtods
////////////////////////////////////////////////////////////////////////////////

- (BOOL) hasRelatedEntities;
- (BOOL) hasFetchedEntities;

@end

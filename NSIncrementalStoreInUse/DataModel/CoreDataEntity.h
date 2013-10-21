//
//  CoreDataEntity.h
//  NSIncrementalStoreInUse
//
//  Created by Andrey Gusev on 10/18/13.
//  Copyright (c) 2013 Andrey Gusev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseDataEntity.h"

@class CoreDataRelatedEntity;

@interface CoreDataEntity : BaseDataEntity

@property (nonatomic, retain) NSNumber * relatedSQLEntityID;
@property (nonatomic, retain) NSOrderedSet *relatedEntities;

//FetchedProperty
@property (nonatomic, readonly) NSArray *sqliteRelatedEntities;

@end

@interface CoreDataEntity (CoreDataGeneratedAccessors)

- (void)insertObject:(CoreDataRelatedEntity *)value inRelatedEntitiesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRelatedEntitiesAtIndex:(NSUInteger)idx;
- (void)insertRelatedEntities:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRelatedEntitiesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRelatedEntitiesAtIndex:(NSUInteger)idx withObject:(CoreDataRelatedEntity *)value;
- (void)replaceRelatedEntitiesAtIndexes:(NSIndexSet *)indexes withRelatedEntities:(NSArray *)values;
- (void)addRelatedEntitiesObject:(CoreDataRelatedEntity *)value;
- (void)removeRelatedEntitiesObject:(CoreDataRelatedEntity *)value;
- (void)addRelatedEntities:(NSOrderedSet *)values;
- (void)removeRelatedEntities:(NSOrderedSet *)values;
@end

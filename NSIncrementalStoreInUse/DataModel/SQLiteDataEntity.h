//
//  SQLiteDataEntity.h
//  NSIncrementalStoreInUse
//
//  Created by Andrey Gusev on 10/18/13.
//  Copyright (c) 2013 Andrey Gusev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseDataEntity.h"

@class SQLiteRelatedEntity;

@interface SQLiteDataEntity : BaseDataEntity

@property (nonatomic, retain) NSNumber * coreDataRelatedEntityID;
@property (nonatomic, retain) NSOrderedSet *relatedEntities;

//FetchedProperty
@property (nonatomic, readonly) NSArray *coreDataRelatedEntities;

@end

@interface SQLiteDataEntity (CoreDataGeneratedAccessors)

- (void)insertObject:(SQLiteRelatedEntity *)value inRelatedEntitiesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRelatedEntitiesAtIndex:(NSUInteger)idx;
- (void)insertRelatedEntities:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRelatedEntitiesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRelatedEntitiesAtIndex:(NSUInteger)idx withObject:(SQLiteRelatedEntity *)value;
- (void)replaceRelatedEntitiesAtIndexes:(NSIndexSet *)indexes withRelatedEntities:(NSArray *)values;
- (void)addRelatedEntitiesObject:(SQLiteRelatedEntity *)value;
- (void)removeRelatedEntitiesObject:(SQLiteRelatedEntity *)value;
- (void)addRelatedEntities:(NSOrderedSet *)values;
- (void)removeRelatedEntities:(NSOrderedSet *)values;
@end

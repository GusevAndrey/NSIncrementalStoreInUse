//
//  SQLiteRelatedEntity.h
//  NSIncrementalStoreInUse
//
//  Created by Andrey Gusev on 10/18/13.
//  Copyright (c) 2013 Andrey Gusev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "RelatedEntityProtocol.h"

@class SQLiteDataEntity;

@interface SQLiteRelatedEntity : NSManagedObject <RelatedEntityProtocol>

@property (nonatomic, retain) NSNumber * entityId;
@property (nonatomic, retain) SQLiteDataEntity *relatedEntitie;

@end

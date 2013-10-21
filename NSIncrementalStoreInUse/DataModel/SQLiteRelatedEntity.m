//
//  SQLiteRelatedEntity.m
//  NSIncrementalStoreInUse
//
//  Created by Andrey Gusev on 10/18/13.
//  Copyright (c) 2013 Andrey Gusev. All rights reserved.
//

#import "SQLiteRelatedEntity.h"
#import "SQLiteDataEntity.h"


@implementation SQLiteRelatedEntity

@dynamic entityId;
@dynamic relatedEntitie;

//==============================================================================
- (NSString *)description {
    
    NSMutableString *descr = [NSMutableString stringWithFormat:@"Name:           %@\n",self.entity.name];
    
    [descr appendFormat:@"EntityID:       %@\n\n",self.entityId];
    [descr appendFormat:@"ParentEntity:\n%@",self.relatedEntitie];
    
    return descr;
}

@end

//
//  BaseDataEntity.m
//  NSIncrementalStoreInUse
//
//  Created by Andrey Gusev on 10/18/13.
//  Copyright (c) 2013 Andrey Gusev. All rights reserved.
//

#import "BaseDataEntity.h"


@implementation BaseDataEntity

@dynamic creationDate;

- (NSOrderedSet *) getRelatedEntities {
    return nil;
}

//==============================================================================
- (NSArray *) getFetchedEntities {
    return nil;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Support Mehtods
////////////////////////////////////////////////////////////////////////////////

- (BOOL) hasRelatedEntities {
    
    return NO;
    
}

//==============================================================================
- (BOOL) hasFetchedEntities {
    
    return NO;
    
}



@end

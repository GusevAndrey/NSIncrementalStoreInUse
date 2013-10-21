//
//  NESPSQLFetchRequest.m
//  looky
//
//  Created by Andrey Gusev on 5/31/13.
//  Copyright (c) 2013 NeoSphere. All rights reserved.
//

#import "NESPSQLFetchRequest.h"

@implementation NESPSQLFetchRequest

+ (NESPSQLFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName {
    
    return [[self alloc] initWithEntityName:entityName];
    
}

@end

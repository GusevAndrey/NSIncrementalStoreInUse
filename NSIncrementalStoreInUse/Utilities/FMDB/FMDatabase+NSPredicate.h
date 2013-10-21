//
//  FMDatabase+NSPredicate.h
//  looky
//
//  Created by Andrey Gusev on 3/29/13.
//  Copyright (c) 2013 NeoSphere. All rights reserved.
//

#import "FMDatabase.h"
#import <CoreData/CoreData.h>

@interface FMDatabase (NSPredicate)

- (NSString *) fmdbQueryFromPredicate:(in NSPredicate *)predicate
                               entity:(in NSEntityDescription *)entity
                               values:(out NSArray **)queryValues
                          shouldBreak:(out BOOL *)shouldBreak;

@end

//
//  MyIncrementalStore.h
//  looky
//
//  Created by Andrey Gusev on 3/27/13.
//  Copyright (c) 2013 NeoSphere. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface MyIncrementalStore : NSIncrementalStore


/**
    Тип PersistentStore-а, для инициализации NSPersistentStoreCoordinator-а
    @returns Тип PersistentStore-а
 */
+ (NSString *) persistentStoreType;


@end

//
//  AppDelegate.m
//  NSIncrementalStoreInUse
//
//  Created by Andrey Gusev on 10/11/13.
//  Copyright (c) 2013 Andrey Gusev. All rights reserved.
//

#import "AppDelegate.h"
#import <CoreData/CoreData.h>

#import "CoreDataEntity.h"
#import "CoreDataRelatedEntity.h"

#import "MyIncrementalStore.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    //Начальное заполнение базы данных
    [self seedDataBase];
    
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Core Data
////////////////////////////////////////////////////////////////////////////////

- (NSManagedObjectContext *) managedObjectContext {

    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _managedObjectContext;
}





- (NSManagedObjectModel *)managedObjectModel {
    
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    return _managedObjectModel;
}





- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    
    // Добавление persistentStore-а CoreData
    NSURL *coreDataStoreUrl = [NSURL fileURLWithPath:[[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"CoreDataBase.sqlite"]];
    
    NSError *error = nil;
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:@"CoreDataStore"
                                                             URL:coreDataStoreUrl
                                                         options:nil
                                                           error:&error]) {
        
        /*Error for store creation should be handled in here*/
        NSLog(@"<NOT SO EPIC, BUT FAIL> CoreDataBase.sqlite не удалось создать. Error: %@",error);
    }
    
    
    
    // Добавление persistentStore-а NSIncrementalStore
    NSURL *incrementalStoreUrl = [NSURL fileURLWithPath:[[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"IncrementalStoreBase.sqlite"]];
    
    error = nil;
    if (![_persistentStoreCoordinator addPersistentStoreWithType:[MyIncrementalStore persistentStoreType]
                                                   configuration:@"IncrementalStore"
                                                             URL:incrementalStoreUrl
                                                         options:nil
                                                           error:&error]) {
        
        /*Error for store creation should be handled in here*/
        
        NSLog(@"<EPIC FAIL> IncrementalStoreBase.sqlite не удалось создать. Error: %@",error);
        
    }
    
    return _persistentStoreCoordinator;
}


- (NSString *)applicationDocumentsDirectory {
    
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
}



////////////////////////////////////////////////////////////////////////////////
#pragma mark - DataBaseSeed
////////////////////////////////////////////////////////////////////////////////

- (void) seedDataBase {

    __weak AppDelegate *wSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        BOOL didSeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"didSeed"];
        
        if (!didSeed) {
            
            //Создание SQLite базы
            
            NSString *preseedBasePath = [[NSBundle mainBundle] pathForResource:@"IncrementalStoreBase" ofType:@"sqlite"];
            NSString *incrementalStorePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"IncrementalStoreBase.sqlite"];
            
            NSError *error = nil;
            if (![[NSFileManager defaultManager] copyItemAtPath:preseedBasePath toPath:incrementalStorePath error:&error]) {
                
                NSLog(@"<EPIC FAIL> IncrementalStoreBase.sqlite не удалось создать. Error: %@",error);
                
            }
            
            //Создание сущностей в CoreData Store
            
            NSEntityDescription *mainEntity = [NSEntityDescription entityForName:@"CoreDataEntity"
                                                          inManagedObjectContext:[wSelf managedObjectContext]];
            NSEntityDescription *relatedEntity = [NSEntityDescription entityForName:@"CoreDataRelatedEntity"
                                                             inManagedObjectContext:[wSelf managedObjectContext]];
            
            NSArray *timeIntervals = @[@(587558058),@(602937258),@(611058858),@(1381617258),@(1382740458)];
            for (int i = 0; i < 5; i++) {
                
                //Создаём одну основную CoreData сущность
                CoreDataEntity *coreDataObject = [[CoreDataEntity alloc] initWithEntity:mainEntity
                                                         insertIntoManagedObjectContext:[wSelf managedObjectContext]];
                
                
                coreDataObject.creationDate = [NSDate dateWithTimeIntervalSince1970:[timeIntervals[i] doubleValue]];
                coreDataObject.relatedSQLEntityID = @(i);
                
                //И одну привязанную к ней
                CoreDataRelatedEntity *coreDataRelatedObject = [[CoreDataRelatedEntity alloc] initWithEntity:relatedEntity
                                                                              insertIntoManagedObjectContext:[wSelf managedObjectContext]];
                coreDataRelatedObject.entityId = @(i);
                [coreDataRelatedObject setRelatedEntitie:coreDataObject];
            }
            
            if ([[wSelf managedObjectContext] save:nil]) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"didSeed"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
    });
}

@end

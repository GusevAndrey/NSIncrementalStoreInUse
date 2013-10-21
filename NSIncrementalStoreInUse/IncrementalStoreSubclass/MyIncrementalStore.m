//
//  MyIncrementalStore.m
//  looky
//
//  Created by Andrey Gusev on 3/27/13.
//  Copyright (c) 2013 NeoSphere. All rights reserved.
//

#import "MyIncrementalStore.h"

#import "FMDatabase+NSFetchRequest.h"
#import "FMDatabaseQueue.h"

#import "DataBaseConfig.h"

@interface MyIncrementalStore () {
    
    //Очередь для работы с SQLite-базой данных
    FMDatabaseQueue *_dbQueue;
    
    //Кеш расфолченных объектов.
    NSCache *_rowCache;
}

@end



@implementation MyIncrementalStore


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initialization
////////////////////////////////////////////////////////////////////////////////

+ (void)initialize {
    [NSPersistentStoreCoordinator registerStoreClass:self
                                        forStoreType:[self persistentStoreType]];
}

//==============================================================================
+ (NSString *)persistentStoreType {
    return NSStringFromClass(self);
}

//==============================================================================
- (BOOL)loadMetadata:(NSError **)error {
    
    NSMutableDictionary *mutableMetadata = [NSMutableDictionary dictionary];
    [mutableMetadata setValue:[[NSProcessInfo processInfo] globallyUniqueString]
                       forKey:NSStoreUUIDKey];
    [mutableMetadata setValue:[[self class] persistentStoreType]
                       forKey:NSStoreTypeKey];
    [self setMetadata:mutableMetadata];
    
    return YES;
}



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init
////////////////////////////////////////////////////////////////////////////////

- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator*)root
                       configurationName:(NSString *)name
                                     URL:(NSURL*)url
                                 options:(NSDictionary *)options {
    
    self = [super initWithPersistentStoreCoordinator:root
                                   configurationName:name
                                                 URL:url
                                             options:options];
    if (self) {
        
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:[url absoluteString]];
        
        _rowCache = [[NSCache alloc] init];
    }
    
    return self;
}


//==============================================================================
- (void)setURL:(NSURL *)url {

    [_dbQueue close];
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:[url absoluteString]];
    
    [super setURL:url];    
}

//==============================================================================
// Gives the store a chance to do any non-dealloc teardown (for example, closing a network connection)
// before removal.
- (void)willRemoveFromPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator {
    
    [_dbQueue close];
    
    [super willRemoveFromPersistentStoreCoordinator:coordinator];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Required Methods
////////////////////////////////////////////////////////////////////////////////

- (id)executeRequest:(NSPersistentStoreRequest *)request
         withContext:(NSManagedObjectContext *)context
               error:(NSError **)error {
    
    //Результат обработки запроса
    __block id result = nil;
    
    //Выборка данных
    if (request.requestType == NSFetchRequestType) {
        
        NSFetchRequest *fRequest = (NSFetchRequest *)request;
        
        switch (fRequest.resultType) {
                
            case NSManagedObjectResultType:
            case NSManagedObjectIDResultType:
            {
                //Массив результатов запроса
                NSMutableArray *items = [NSMutableArray array];                
                                              
                [_dbQueue inDatabase:^(FMDatabase *db) {
                    
                    //Выборка уникальных идентификаторов объектов по запросу
                    BOOL shouldBreak = NO;
                    FMResultSet *requestResult = [db executeQueryWithFetchRequest:fRequest
                                                                      shouldBreak:&shouldBreak];
                    
                    //Обрабатываем результат только, если запрос был выполнен
                    if (!shouldBreak) {
                        
                        while ([requestResult next]) {
                            
                            //Уникальный идентификатор объекта
                            id rowId = [requestResult objectForColumnIndex:0];
                            
                            //Если его найти удалось - добавляем его в массив резлутатов
                            if (rowId && (rowId != [NSNull null])) {
                                [items addObject:rowId];
                            }
                        }
                        
                        if (!requestResult) {
                            
                            if (error != NULL)
                                *error = [db lastError];
                        }
                        
                        [requestResult close];
                    }
                }];
                
                
                NSEntityDescription *entity = fRequest.entity;
                
                //Для абстрактных сущностей определяем их полноценные полные подсущности.
                if (entity.isAbstract) {
                    
                    NSString *fullSubentityName = [entity.userInfo valueForKey:kMIStoreSubentityName];
                    entity = [[entity subentitiesByName] valueForKey:fullSubentityName] ?: entity;
                }
                
                //Массив fault-ов
                if (fRequest.resultType == NSManagedObjectResultType) {
                    
                    
                    result = [self mapArray:items withBlock:^id(id item) {
                        
                        NSManagedObjectID *oid = [self newObjectIDForEntity:entity
                                                            referenceObject:item];
                        return [context objectWithID:oid];
                        
                    }];
                    
                    
                }
                
                //Массив objectID
                else {
                    
                    result = [self mapArray:items withBlock:^id(id item) {
                        
                        NSManagedObjectID *oid = [self newObjectIDForEntity:entity
                                                            referenceObject:item];
                        return oid;
                        
                    }];
                }
                
            }
                break;
                                
                
            case NSDictionaryResultType:
                {
                    NSMutableArray *dicts = [NSMutableArray array];
                    
                    [_dbQueue inDatabase:^(FMDatabase *db) {
                        
                        BOOL shouldBreak = NO;
                        FMResultSet *requestResult = [db executeQueryWithFetchRequest:fRequest
                                                                          shouldBreak:&shouldBreak];
                        
                        //Обрабатываем результат только, если запрос был выполнен
                        if (!shouldBreak) {
                            
                            while ([requestResult next]) {
                                
                                NSDictionary *objectDataDict = [self valuesFromRequest:requestResult valuesToFetch:fRequest.propertiesToFetch];
                                
                                if (objectDataDict)
                                    [dicts addObject:objectDataDict];
                                
                            }
                            
                            if (!requestResult) {
                                
                                if (error != NULL)
                                    *error = [db lastError];
                            }
                            
                            [requestResult close];
                        }
                    }];
                    
                    result = dicts;           
                }
                
                break;
        
                
            case NSCountResultType: {

                
                [_dbQueue inDatabase:^(FMDatabase *db) {
                    
                    //Подсчёт количества объектов в базе
                    NSNumber *countOfObjects = [db countObjectsWithFetchRequest:fRequest
                                                                          error:error];
                    result = @[countOfObjects];
                    
                }];
                
            }
                break;
                
                
                
                
            default:
                
                NSLog(@"<%@> Unsupported fetchResultType: %u (fetchRequest: %@)",[self class],fRequest.resultType,fRequest);
                
                break;
        }
    }
    
    //Сохранение данных
    else if (request.requestType == NSSaveRequestType) {
    
        NSSaveChangesRequest *saveRequest = (NSSaveChangesRequest *)request;
        
        __block BOOL success = YES;
        
        // Objects that were deleted from the calling context.
        NSSet *deletedObjects = [saveRequest deletedObjects];
        if (deletedObjects.count) {
            
            [_dbQueue inDatabase:^(FMDatabase *db) {
                
                success = [db deleteObjects:deletedObjects];
                
                if (!success) {
                    
                    if (error != NULL)
                        *error = [db lastError];
                }
            }];
            
        }

//TODO:
//        // Objects that were inserted into the calling context.
//        - (NSSet *)insertedObjects;
//        // Objects that were modified in the calling context.
//        - (NSSet *)updatedObjects;
//        // Objects that were flagged for optimistic locking on the calling context via detectConflictsForObject:.
//        - (NSSet *)lockedObjects;
        
        //По данному типу запроса метод должен вовзращать пустой массив, согласно документации.
        result = @[];
    }
    
    //Неизвестный тип запроса
    else {
      
      //TODO: возвращать nil и ошибку
      NSLog(@"<%@> Unsupported requestType: %u (request: %@)",[self class],request.requestType,request);
        
    }
    
//    NSLog(@"ExecuteRequest results: %i",[result count]);
    return result;
}


//==============================================================================
- (NSArray *)obtainPermanentIDsForObjects:(NSArray *)array error:(NSError **)error {

    // not implemented, we don't support saving for now
    return nil;
}


//==============================================================================
- (NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID*)objectID
                                        withContext:(NSManagedObjectContext*)context
                                              error:(NSError**)error {

    //Node данных объекта, либо nil в случае отсутствия требуемого объекта в базе
    NSIncrementalStoreNode *cachedNode = [_rowCache objectForKey:objectID];
    
    if (!cachedNode) {
    
        __block NSDictionary *objectDataDict = nil;
        
        [_dbQueue inDatabase:^(FMDatabase *db) {
            
            objectDataDict = [self valuesForObjectWithID:objectID fromDB:db error:error];
            
        }];
        
        
        //Если данные есть - возвращаем результат
        if (objectDataDict) {
            
            NSIncrementalStoreNode *node = [[NSIncrementalStoreNode alloc] initWithObjectID:objectID
                                                                                 withValues:objectDataDict
                                                                                    version:1];
            if (node)
                [_rowCache setObject:node forKey:objectID];
            
            return node;
        }
        
        //Если данных нет - возвращаем ошибку в *error и nil в качестве результата
        else {
            
            return nil;
            
        }
    }
    
    //Если кеш есть - возвращаем данные сразуже
    else {
        return cachedNode;
    }
}

//==============================================================================
- (id)newValueForRelationship:(NSRelationshipDescription *)relationship
              forObjectWithID:(NSManagedObjectID *)objectID
                  withContext:(NSManagedObjectContext *)context
                        error:(NSError **)error {
    
    //Массив результатов запроса
    NSMutableArray *items = [NSMutableArray array];
    
    [_dbQueue inDatabase:^(FMDatabase *db) {
        
        //Выборка уникальных идентификаторов объектов по запросу
        FMResultSet *requestResult = [db selectSimpleRelationship:relationship
                                                  forObjectWithID:objectID];
        
        while ([requestResult next]) {
            
            //Уникальный идентификатор объекта
            id rowId = [requestResult objectForColumnIndex:0];
            
            //Если его найти удалось - добавляем его в массив резлутатов
            if (rowId && (rowId != [NSNull null])) {
                [items addObject:rowId];
            }
        }
        
        if (!requestResult) {
            
            if (error != NULL)
                *error = [db lastError];
        }
        
        [requestResult close];
    }];
    
    NSEntityDescription *entity = relationship.destinationEntity;
    
    //Для абстрактных сущностей определяем их полноценные полные подсущности.
    if (entity.isAbstract) {
        
        NSString *fullSubentityName = [entity.userInfo valueForKey:kMIStoreSubentityName];
        entity = [[entity subentitiesByName] valueForKey:fullSubentityName] ?: entity;
    }
    
    //Массив fault-ов
    NSArray *result = [self mapArray:items withBlock:^id(id item) {
        
        NSManagedObjectID *oid = [self newObjectIDForEntity:entity
                                            referenceObject:item];
        return oid;
        
    }];
    
    //В зависимости от типа отношения возвращаеми результат разным образом
    if (relationship.isToMany) {
        return result;
    }
    else {
        return [result lastObject] ?: [NSNull null];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Support Methods
////////////////////////////////////////////////////////////////////////////////

//Выборка данных по объекту с заданным objectID из заданной базы
- (NSDictionary *) valuesForObjectWithID:(NSManagedObjectID *)objectID fromDB:(FMDatabase *)db error:(NSError **)error {
    
    //Выборка данных объекта по его objectID
    FMResultSet *requestResult = [db objectQueryWithID:objectID];
    
    //Результирующий словарь значений
    NSMutableDictionary *objectDataDict = nil;
    
    if ([requestResult next]) {
        
        objectDataDict = [NSMutableDictionary dictionary];
        
        //По всем полям объекта
        NSDictionary *entityProperties = objectID.entity.propertiesByName;
        for (NSString *nextProperyName in [entityProperties allKeys]) {
            
            //Описание поля объекта
            NSPropertyDescription *pDesc = [entityProperties valueForKey:nextProperyName];
            
            //Пропускаем транзиентные атрибуты:
            if (pDesc.isTransient) continue;
                        
            //Атрибуты
            if ([pDesc isKindOfClass:[NSAttributeDescription class]]) {
                
                NSString *attributeName = [pDesc.userInfo objectForKey:kMIStoreAttributeName] ?: [[pDesc name] lowercaseString];
                
                NSAttributeDescription *attributeDesc = (NSAttributeDescription *)pDesc;
                
                id attributeValue = nil;
                
                switch (attributeDesc.attributeType) {
                        
                    case NSTransformableAttributeType: {
                        
                        id valueToTransform = [requestResult objectForColumnName:attributeName];
                        
                        NSString *transformerName = [attributeDesc valueTransformerName];
                        NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:transformerName];
                        
                        attributeValue = [transformer reverseTransformedValue:valueToTransform];
                    }
                        break;

                        
                    case NSDateAttributeType:
                        
                        attributeValue = [requestResult dateForColumn:attributeName];
                        
                        break;
                        
                        
                    default:
                        
                        attributeValue = [requestResult objectForColumnName:attributeName];
                        
                        break;
                }
                
                
                if (attributeValue && (attributeValue != [NSNull null])) {
                    
                    [objectDataDict setValue:attributeValue forKey:[pDesc name]];
                    
                }
            }
            
            //Отношения
            else if ([pDesc isKindOfClass:[NSRelationshipDescription class]]) {
                
                //Пропускаем все отношения (они должны получаться в newValueForRelationship:...)
                continue;
                
            }
        }
    }
    else {
        
        if (error != NULL)
            *error = [db lastError];
    }
    
    [requestResult close];
    
    
    return objectDataDict;
}

//==============================================================================
//Получение значений заданных полей из данных requestResult. Передаваемый requestResult должен уже получить сообщение next ( [requestResult next]; )
- (NSDictionary *) valuesFromRequest:(FMResultSet *)requestResult valuesToFetch:(NSArray *)valuesToFetch {

    //Результирующий словарь значений
    NSMutableDictionary *objectDataDict = [NSMutableDictionary dictionary];

    for (NSPropertyDescription *pDesc in valuesToFetch) {
                
        //Пропускаем транзиентные атрибуты:
        if (pDesc.isTransient) continue;
        
        //Атрибуты
        if ([pDesc isKindOfClass:[NSAttributeDescription class]]) {
            
            NSString *attributeName = [pDesc.userInfo objectForKey:kMIStoreAttributeName] ?: [[pDesc name] lowercaseString];
            
            NSAttributeDescription *attributeDesc = (NSAttributeDescription *)pDesc;
            
            id attributeValue = nil;
            
            switch (attributeDesc.attributeType) {
                    
                case NSTransformableAttributeType: {
                  
                    NSLog(@"<ERROR> NSTransformableAttributeType is not supported for NSDictionaryResultType");
                
                }
                    break;
                    
                    
                case NSDateAttributeType:
                    
                    attributeValue = [requestResult dateForColumn:attributeName];
                    
                    break;
                    
                    
                default:
                    
                    attributeValue = [requestResult objectForColumnName:attributeName];
                    
                    break;
            }
            
            
            if (attributeValue && (attributeValue != [NSNull null])) {
                
                [objectDataDict setValue:attributeValue forKey:[pDesc name]];
                
            }
        }
        
        //Отношения
        else if ([pDesc isKindOfClass:[NSRelationshipDescription class]]) {
            
            NSLog(@"<ERROR> Relationship is not supported for NSDictionaryResultType");
            
        }
    }
    
    return objectDataDict;
}

//==============================================================================
//Выполнение заданного полноценного запроса на базе. В результате получаем массив значений 0-го поля запроса (изначально выбирается rowId). nil в случае ошибки, пустой массив в случае отсутствия результатов
- (NSArray *) executeQuery:(NSString *)sqlQuery arguments:(NSArray *)arguments error:(NSError **)error {
    
    if (!sqlQuery) return nil;
    
    __block NSArray *items = nil;
    
    [_dbQueue inDatabase:^(FMDatabase *db) {
        
        items = [self executeQuery:sqlQuery arguments:arguments database:db error:error];
        
    }];
    
    return items;
}

//==============================================================================
//Выполнение заданного полноценного запроса на базе. В результате получаем массив значений 0-го поля запроса (изначально выбирается rowId). nil в случае ошибки, пустой массив в случае отсутствия результатов
- (NSArray *) executeQuery:(NSString *)sqlQuery arguments:(NSArray *)arguments database:(FMDatabase *)db error:(NSError **)error {
    
    if (!sqlQuery) return nil;
    
    __block NSMutableArray *items = [NSMutableArray array];
    
    FMResultSet *requestResult = [db executeQuery:sqlQuery withArgumentsInArray:arguments];
    
    while ([requestResult next]) {
        
        //Уникальный идентификатор объекта
        id rowId = [requestResult objectForColumnIndex:0];
        
        //Если его найти удалось - добавляем его в массив результатов
        if (rowId && (rowId != [NSNull null])) {
            [items addObject:rowId];
        }
    }
    
    if (!requestResult) {
        
        if (error != NULL)
            *error = [db lastError];
        
        items = nil;
    }

    [requestResult close];
    
    return items;
}

//==============================================================================
//Получение массива преобразованных объектов исходного массива путём выполнения на каждом из них заданного блока
- (NSArray *) mapArray:(NSArray *)array withBlock:(id(^)(id item))mapBlock {
    
    if (!array) return nil;
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:array.count];
    
    for (id nextObject in array) {
        [result addObject:mapBlock(nextObject)];
    }
    
    return result;
}

@end






//
//  FMDatabase+NSFetchRequest.m
//  looky
//
//  Created by Andrey Gusev on 3/27/13.
//  Copyright (c) 2013 NeoSphere. All rights reserved.
//
#import <CoreData/CoreData.h>
#import "FMDatabase+NSFetchRequest.h"
#import "FMDatabase+NSPredicate.h"

#import "DataBaseConfig.h"
#import "NESPSQLFetchRequest.h"


@implementation FMDatabase (NSFetchRequest)


//Производит подсчёт объектов, удовлетворяющих переданному fetchRequest-у
- (NSNumber *) countObjectsWithFetchRequest:(NSFetchRequest *)fRequest error:(NSError **)error {
    
    //Аргументы запроса
    NSArray *queryArguments = nil;
    
    //Where-клауза
    BOOL shouldBreakRequest = NO;
    NSString *whereString = [self fmdbQueryFromPredicate:fRequest.predicate
                                                  entity:fRequest.entity
                                                  values:&queryArguments
                                             shouldBreak:&shouldBreakRequest];
    
    //Если запрос необходимо прервать - завершаем выполенение, возвращая результат, будто ничего не нашли без ошибок.
    if (shouldBreakRequest) {
        return [NSNumber numberWithInt:0];
    }

    //Название таблицы сущности
    NSString *entityTable = [fRequest.entity.userInfo objectForKey:kMIStoreEntityTable] ?: [fRequest.entityName lowercaseString];
    
    //Результирующая строка SQL-запроса
    NSMutableString *queryFormatStr = [NSMutableString stringWithFormat:@"SELECT COUNT(*) FROM %@",entityTable];
    
    if (whereString) {
        [queryFormatStr appendFormat:@" WHERE %@",whereString];
    }
    
    //Сортировка
    NSString *orderByString = [self orderQueryFromRequest:fRequest];
    if (orderByString) {
        [queryFormatStr appendFormat:@" ORDER BY %@",orderByString];
    }
    
    //Лимит
    if ([fRequest fetchLimit])
        [queryFormatStr appendFormat:@" LIMIT %i",[fRequest fetchLimit]];
    
    //Отступ
    if ([fRequest fetchOffset])
        [queryFormatStr appendFormat:@" OFFSET %i",[fRequest fetchOffset]];
    
    //Результирующее количество записей
    NSNumber *resultsCount = nil;
    
    FMResultSet *requestResult = [self executeQuery:queryFormatStr];
    if ([requestResult next]) {
        
        //Уникальный идентификатор объекта
        resultsCount = [requestResult objectForColumnIndex:0];
        
    }
    else {
        
        resultsCount = [NSNumber numberWithInt:0];
        
    }
    
    //Если ответа не было - ошибка
    if (!requestResult) {
        *error = [self lastError];
    }
    
    [requestResult close];
    
    return resultsCount;
}



//==============================================================================
//Производит выборку данных на основании переданного fetchRequest-а
- (FMResultSet *) executeQueryWithFetchRequest:(NSFetchRequest *)fRequest shouldBreak:(out BOOL *)shouldBreak {

    //Результирующая строка SQL-запроса
    NSString *queryFormatStr = nil;
    
    //Аргументы запроса
    NSArray *queryArguments = nil;
    
    //Специальный запрос прямиком в базу
    if ([fRequest isKindOfClass:[NESPSQLFetchRequest class]]) {
        
        NESPSQLFetchRequest *fullSQLQuery = (NESPSQLFetchRequest *)fRequest;
        
        queryFormatStr = fullSQLQuery.fullSQLQuery;
        queryArguments = fullSQLQuery.queryArgunments;
    }
    
    //Обычный fetchRequest
    else {
        
        //Where-клауза
        BOOL shouldBreakRequest = NO;
        NSString *whereString = [self fmdbQueryFromPredicate:fRequest.predicate
                                                      entity:fRequest.entity
                                                      values:&queryArguments
                                                 shouldBreak:&shouldBreakRequest];
        
        //Если запрос необходимо прервать - завершаем выполенение, возвращая результат, будто ничего не нашли без ошибок.
        if (shouldBreakRequest) {
            *shouldBreak = YES;
            return nil;
        }
        
        //Название таблицы сущности
        NSString *entityTable = [fRequest.entity.userInfo objectForKey:kMIStoreEntityTable] ?: [fRequest.entityName lowercaseString];
        
        NSString *fieldsToFetch = nil;
        
        //Выборка определённого списка полей
        if (fRequest.resultType == NSDictionaryResultType) {
            
            NSMutableArray *fieldsToFetchArr = [NSMutableArray arrayWithCapacity:fRequest.propertiesToFetch.count];
            for (NSPropertyDescription *nextProperty in fRequest.propertiesToFetch) {
                
                NSString *fieldToFetch = [nextProperty.userInfo objectForKey:kMIStoreAttributeName] ?: [nextProperty.name lowercaseString];
                [fieldsToFetchArr addObject:fieldToFetch];
            }
           
            fieldsToFetch = [fieldsToFetchArr componentsJoinedByString:@", "];
        }
        
        //Выборка уникальных идентификаторов
        else {
            
            //Название поля, представляющего rowId
            fieldsToFetch = [fRequest.entity.userInfo objectForKey:kMIStoreRowIdField] ?: @"rowId";
            
        }
        
        //Результирующая строка SQL-запроса
        queryFormatStr = [NSString stringWithFormat:@"SELECT %@ FROM %@",fieldsToFetch,entityTable];
        
        
        if (whereString) {
            queryFormatStr = [queryFormatStr stringByAppendingFormat:@" WHERE %@",whereString];
        }
        
        //Сортировка
        NSString *orderByString = [self orderQueryFromRequest:fRequest];
        if (orderByString) {
            queryFormatStr = [queryFormatStr stringByAppendingFormat:@" ORDER BY %@",orderByString];
        }
        
        //Лимит
        if ([fRequest fetchLimit])
            queryFormatStr = [queryFormatStr stringByAppendingFormat:@" LIMIT %i",[fRequest fetchLimit]];
        
        //Отступ
        if ([fRequest fetchOffset])
            queryFormatStr = [queryFormatStr stringByAppendingFormat:@" OFFSET %i",[fRequest fetchOffset]];
        
        //    NSLog(@"  Original FetchRquest: %@",fRequest);
        //    NSLog(@"   Result query string: %@",queryFormatStr);
        //    NSLog(@"Result query arguments: %@",queryArguments);
    }
    
    return [self executeQuery:queryFormatStr withArgumentsInArray:queryArguments];
}


//==============================================================================
//Выборка всех данных для конкретного объекта по его objectID.
- (FMResultSet *) objectQueryWithID:(NSManagedObjectID *)objectID {
    
    //Другие persistenStore-ы не поддерживаютcя
    if (![objectID.persistentStore isKindOfClass:[NSIncrementalStore class]]) return nil;
    
    //уникальный идентификатор выбираемого объекта.
    id rowId = [(NSIncrementalStore *)objectID.persistentStore referenceObjectForObjectID:objectID];
    
    //Название таблицы сущности
    NSString *entityTable = [objectID.entity.userInfo objectForKey:kMIStoreEntityTable] ?: [objectID.entity.name lowercaseString];
    //Название поля, представляющего rowId
    NSString *rowIdField = [objectID.entity.userInfo objectForKey:kMIStoreRowIdField] ?: @"rowId";
    
    //Результирующая строка SQL-запроса
    NSString *queryFormatStr = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ == %%@",entityTable,rowIdField];
    
//    NSLog(@"Result query string: %@",queryFormatStr);
//    NSLog(@"Result %@ value: %@",rowIdField,rowId);
    
    return [self executeQueryWithFormat:queryFormatStr,rowId];    
}


//==============================================================================
- (NSString *) orderQueryFromRequest:(NSFetchRequest *)fRequest {

    if (!fRequest || ![fRequest.sortDescriptors count]) return nil;
    
    NSMutableArray *orderByTerms = [NSMutableArray arrayWithCapacity:[fRequest.sortDescriptors count]];
    for (NSSortDescriptor *nextSortDescriptor in fRequest.sortDescriptors) {

        NSPropertyDescription *pDesc = [fRequest.entity.propertiesByName valueForKey:nextSortDescriptor.key];
        NSString *orderField = [pDesc.userInfo valueForKey:kMIStoreAttributeName] ?: [nextSortDescriptor.key lowercaseString];
        
        NSString *sortTerm = [NSString stringWithFormat:@"%@ %@", orderField, nextSortDescriptor.ascending ? @"ASC" : @"DESC"];
        
        [orderByTerms addObject:sortTerm];
    }
    
    
    return [orderByTerms componentsJoinedByString:@", "];
}

//==============================================================================
- (BOOL) deleteObjects:(NSSet *)objects {

    //Сгруппированные по сущностям идентификаторы удаляемых объектов. Словарь <EntityDescription> - > [rowId1, rowId2,...]
    NSMutableDictionary *rowIdByEntities = [NSMutableDictionary dictionary];

    BOOL result = YES;
    
    for (NSManagedObject *nextObject in objects) {

        NSManagedObjectID *nextId = nextObject.objectID;
        
        //Другие persistenStore-ы не поддерживаютcя
        if (![nextId.persistentStore isKindOfClass:[NSIncrementalStore class]]) {
            
            continue;
        }
        
        //уникальный идентификатор выбираемого объекта.
        id rowId = [(NSIncrementalStore *)nextId.persistentStore referenceObjectForObjectID:nextId];
        
        NSMutableArray *rowIds = [rowIdByEntities objectForKey:nextId.entity];
        
        if (!rowIds) {
            rowIds = [NSMutableArray arrayWithObject:rowId];
            [rowIdByEntities setObject:rowIds forKey:nextId.entity];
        }
        else {
            [rowIds addObject:rowId];
        }
    }
    
    //Для каждой сущности производим удаление
    for (NSEntityDescription *nextEntity in [rowIdByEntities allKeys]) {

        //Название таблицы сущности
        NSString *entityTable = [nextEntity.userInfo objectForKey:kMIStoreEntityTable] ?: [nextEntity.name lowercaseString];
        
        //Название поля, представляющего rowId
        NSString *rowIdField = [nextEntity.userInfo objectForKey:kMIStoreRowIdField] ?: @"rowId";
        
        NSArray *rowIds = [rowIdByEntities objectForKey:nextEntity];
        NSString *inClauseData = [rowIds componentsJoinedByString:@","];
        
        //Результирующая строка SQL-запроса
        NSString *queryFormatStr = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ IN (%@)",entityTable,rowIdField,inClauseData];
        
        BOOL success = [self executeUpdate:queryFormatStr];
        
        NSLog(@"Objects of entity: %@ %@",nextEntity.name, success ? @"successfully delete" : @"delete with error");
        if (!success) {
            NSLog(@"error: %@",[self lastError]);
            result = NO;
        }
    }
    
    return result;
}


//==============================================================================
//Производит выборку данных для простого отношения: связь по идентификаторам через таблицу связи
- (FMResultSet *) selectSimpleRelationship:(NSRelationshipDescription *)relationship
                           forObjectWithID:(NSManagedObjectID *)objectID {
    
    //select <RowId> from <entityTable2> join <entityTable1>_<entityTable2> on <entityTable2>ID == <RowId>  where <entityTable2>ID == objectID
    
    NSEntityDescription *sourceEntity = relationship.entity;

    //Название таблицы первой сущности
    NSString *entityTable1 = [sourceEntity.userInfo objectForKey:kMIStoreEntityTable] ?: [sourceEntity.name lowercaseString];
    
    
    NSEntityDescription *targetEntity = relationship.destinationEntity;
    
    //Название таблицы второй сущности
    NSString *entityTable2 = [targetEntity.userInfo objectForKey:kMIStoreEntityTable] ?: [targetEntity.name lowercaseString];
    
    //Название поля, представляющего rowId
    NSString *rowIdField = [targetEntity.userInfo objectForKey:kMIStoreRowIdField] ?: @"rowId";
    
    
    //Название таблицы связи состоит из названий обеих таблиц, в алфавитном порядке и разделённых _
    NSComparisonResult result = [entityTable1 compare:entityTable2];
    NSString *relationTablePrefix = entityTable1;
    NSString *relationTableSuffix = entityTable2;
    
    if (result == NSOrderedDescending) {
        relationTablePrefix = entityTable2;
        relationTableSuffix = entityTable1;
    }
    NSString *relationTable = [NSString stringWithFormat:@"%@_%@",relationTablePrefix,relationTableSuffix];
    
    
    //Результирующая строка SQL-запроса
    NSString *queryFormatStr = [NSString stringWithFormat:@"SELECT %@ FROM %@ JOIN %@ ON %@id == %@ WHERE %@id == ?",rowIdField,entityTable2,relationTable,entityTable2,rowIdField,entityTable2];
    
    
    //Другие persistenStore-ы не поддерживаютcя
    if (![objectID.persistentStore isKindOfClass:[NSIncrementalStore class]]) {
        
        return nil;
    }
    
    //уникальный идентификатор выбираемого объекта.
    id rowId = [(NSIncrementalStore *)objectID.persistentStore referenceObjectForObjectID:objectID];
    
    return [self executeQuery:queryFormatStr withArgumentsInArray:@[rowId]];
}



@end

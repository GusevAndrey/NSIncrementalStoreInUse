//
//  FMDatabase+NSFetchRequest.h
//  looky
//
//  Created by Andrey Gusev on 3/27/13.
//  Copyright (c) 2013 NeoSphere. All rights reserved.
//

#import "FMDatabase.h"

/**
	Категория для работы с FMDatabase, используя fetchRequest-ы
 */
@interface FMDatabase (NSFetchRequest)

/**
    Производит подсчёт объектов, удовлетворяющих переданному fetchRequest-у
	@param fRequest fetchRequest для выборки данных.
	@param error Cсылка на переменную для размещения в ней произошедшей ошибки.
	@returns Количество записей, удовлетворяющих fetchRequest-у. В случае ошибки возвращается 0.
 */
- (NSNumber *) countObjectsWithFetchRequest:(NSFetchRequest *)fRequest error:(NSError **)error;


/**
    Производит выборку данных на основании переданного fetchRequest-а
    
    Производит выборку данных заданных полей в случае FetchRequest.resultType == NSDictionatyResultType, иначе 
    производит выборку уникальных идентификаторов объектов из базы fetchRequest-а
 
    *NOTE*
        Идентификатор представляет собой NSNumber, хранящийся по 0-ому индексу в FMResultSet (следует обращаться objectForColumnIndex:0)
 
    @param fRequest fetchRequest для выборки данных.
    @param shouldBreak Выходной параметр. Сигнализирует о том, что выполнение запроса было прервано. При выставленном флаге shouldBreak функиця возвращает nil;
    @returns Набор результатов (объект FMResultSet), либо nil в случае ошибки.
 */
- (FMResultSet *) executeQueryWithFetchRequest:(NSFetchRequest *)fRequest shouldBreak:(out BOOL *)shouldBreak;


/**
	Выборка всех данных для конкретного объекта по его objectID.
 
    *WARNING*
        Для работы метода, переданный objectID должен пренадлежать дочернему классу NSIncrementalStore. 
        В противном случае метод вернёт nil, но не выставит ошибку в lastError.
 
	@param objectID ObjectID объекта, данные для которого необходимо достать из базы.
	@returns Набор результатов (объект FMResultSet), либо nil в случае ошибки.
 */
- (FMResultSet *) objectQueryWithID:(NSManagedObjectID *)objectID;


// ALPHA-version ===================================================================================================

- (BOOL) deleteObjects:(NSSet *)objectsIDs;

//Производит выборку данных для простого отношения: связь по идентификаторам через таблицу связи
- (FMResultSet *) selectSimpleRelationship:(NSRelationshipDescription *)relationship
                           forObjectWithID:(NSManagedObjectID *)objectID;

@end

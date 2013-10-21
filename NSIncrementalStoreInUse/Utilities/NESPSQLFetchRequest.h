//
//  NESPSQLFetchRequest.h
//  looky
//
//  Created by Andrey Gusev on 5/31/13.
//  Copyright (c) 2013 NeoSphere. All rights reserved.
//

#import <CoreData/CoreData.h>

/**
	Спецциальный NSFetchRequest, позволяющий осуществить прямой запрос в SQLite базу.
 */
@interface NESPSQLFetchRequest : NSFetchRequest


/**
	Полный SQL запрос с плейсхолдерами '?' вместо значений параметров.
 */
@property (nonatomic,strong) NSString *fullSQLQuery;


/**
	Аргументы запроса. Должны быть заполнены тем же количеством данных и в том же порядке, что и плейсхоледры в fullSQLQuery.
 */
@property (nonatomic,strong) NSArray *queryArgunments;




/**
	Создание объекта-запроса к базе по заданной сущности.
	@param entityName Название сущности, выборку для которой необходимо осуществить.
 
	@returns Заготовка объекта-запроса. Должна быть заполнена fullSQLQuery дополнительно перед отправкой.
 */
+ (NESPSQLFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName;


@end

//
//  DataBaseConfig.h
//  NSIncrementalStoreInUse
//
//  Created by Andrey Gusev on 4/10/13.
//  Copyright (c) 2013 NeoSphere. All rights reserved.
//



////////////////////////////////////////////////////////////////////////////////
#pragma mark - LIStore Entity keys
////////////////////////////////////////////////////////////////////////////////

//Ключи meta-данных UserInfo entity-ей.

//По ключу лежит название таблицы соответствующей сущносте. При отсутствии значения в качестве названия таблицы используется lowercase-название самой сущности.
static NSString * const kMIStoreEntityTable         = @"entityTable";


//По ключу лежит название поля основного идентификатора сущности в таблице. При отсутствии значения в качестве основного идентификатора используется поле rowId. Необходимо для постороения ObjectID.
static NSString * const kMIStoreRowIdField          = @"rowIdField";

//По ключу лежит название полноценной подсущности для текущей абстрактной сущности. При отсутствии значения при выдаче используется сама абстрактная сущность
static NSString * const kMIStoreSubentityName   = @"SQLSubentityName";


//Ключи meta-данных UserInfo атрибутов entity-ей.

//По ключу лежит название поля в таблице. При отсутствии значения в качестве названия поля используется lowercase-название самого атрибута сущности.
static NSString * const kMIStoreAttributeName       = @"attributeName";
//
//  FMDatabase+NSPredicate.m
//  looky
//
//  Created by Andrey Gusev on 3/29/13.
//  Copyright (c) 2013 NeoSphere. All rights reserved.
//

#import "FMDatabase+NSPredicate.h"
#import "DataBaseConfig.h"

@implementation FMDatabase (NSPredicate)

- (NSString *) fmdbQueryFromPredicate:(in NSPredicate *)predicate
                               entity:(in NSEntityDescription *)entity
                               values:(out NSArray **)queryValues
                          shouldBreak:(out BOOL *)shouldBreak {
    
    //Если предикат не задан - ничего не возвращаем
    if (!predicate) return nil;
    
    if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        
        return [self fmdbQueryFromComparisonPredicate:(NSComparisonPredicate *)predicate
                                               entity:entity
                                               values:queryValues
                                          shouldBreak:shouldBreak];
        
    }
    
    else if ([predicate isKindOfClass:[NSCompoundPredicate class]]) {
        
        return [self fmdbQueryFromCompoundPredicate:(NSCompoundPredicate *)predicate
                                             entity:entity
                                             values:queryValues
                                        shouldBreak:shouldBreak];
    }
    
    NSLog(0, @"<ERROR> didn't understand predicate: %@",predicate);
    return nil;
}




//==============================================================================
- (NSString *) fmdbQueryFromComparisonPredicate:(in NSComparisonPredicate *)cp
                                         entity:(in NSEntityDescription *)entity
                                         values:(out NSArray **)queryValues
                                    shouldBreak:(out BOOL *)shouldBreak {
    
    //Операция для работы со значениями
    NSString *operatorString = nil;
    //Операция для работы с NULL-ами
    NSString *operatorStringForNULL = nil;
    
    switch (cp.predicateOperatorType) {
            
        case NSLessThanPredicateOperatorType:
            operatorString = @" < ";
            operatorStringForNULL = @" IS NOT ";
            break;
            
        case NSLessThanOrEqualToPredicateOperatorType:
            operatorString = @" <= ";
            operatorStringForNULL = @" IS NOT ";
            break;
            
        case NSGreaterThanPredicateOperatorType:
            operatorString = @" > ";
            operatorStringForNULL = @" IS NOT ";
            break;
            
        case NSGreaterThanOrEqualToPredicateOperatorType:
            operatorString = @" >= ";
            operatorStringForNULL = @" IS NOT ";
            break;
            
        case NSEqualToPredicateOperatorType:
            operatorString = @" == ";
            operatorStringForNULL = @" IS ";
            break;
            
        case NSNotEqualToPredicateOperatorType:
            operatorString = @" != ";
            operatorStringForNULL = @" IS NOT ";
            break;
            
        case NSInPredicateOperatorType:
            operatorString = @" IN ";
            operatorStringForNULL = @" IS ";
            break;
            
        default:
            
            /*
             NOT SUPPORTED:
             
             NSMatchesPredicateOperatorType,
             NSLikePredicateOperatorType,
             NSBeginsWithPredicateOperatorType,
             NSEndsWithPredicateOperatorType,
             NSInPredicateOperatorType,
             NSContainsPredicateOperatorType,
             NSBetweenPredicateOperatorType
             
             */
            
            break;
    }
    
    if (!operatorString) {
        NSLog(0, @"<ERROR> NSPredicate not supported operation type. Type: %i Predicate: %@",cp.predicateOperatorType,cp);
        return nil;
    }

//    - (NSComparisonPredicateModifier)comparisonPredicateModifier;
//    - (NSComparisonPredicateOptions)options;
    
    
    
    //Результирующая операция
    NSString *resultOperation = operatorString;
    
    NSMutableArray *expressionsValues = [NSMutableArray array];
    
    //Left expression
    BOOL shouldBreakLeftExpression = NO;
    NSString *leftExpressionStr = [self expStringFromExpression:cp.leftExpression
                                                         entity:entity
                                                      putValues:expressionsValues
                                                    shouldBreak:&shouldBreakLeftExpression];
    
    if ([leftExpressionStr isEqualToString:@"NULL"]) {
        resultOperation = operatorStringForNULL;
    }
    
    
    //Right expression
    BOOL shouldBreakRightExpression = NO;
    NSString *rightExpressionStr = [self expStringFromExpression:cp.rightExpression
                                                          entity:entity
                                                       putValues:expressionsValues
                                                     shouldBreak:&shouldBreakRightExpression];
    
    if ([rightExpressionStr isEqualToString:@"NULL"]) {
        resultOperation = operatorStringForNULL;
    }
    
    //Прерываем выполнение запроса если хоть 1 выражение этого требует
    *shouldBreak = shouldBreakLeftExpression || shouldBreakRightExpression;
    
    if (!*shouldBreak && (!leftExpressionStr || !rightExpressionStr))
        NSLog(@"<ERROR> didn't understand predicate: %@",cp);
    
    *queryValues = expressionsValues.count ? expressionsValues : nil;
    return [NSString stringWithFormat:@"%@ %@ %@",leftExpressionStr,resultOperation,rightExpressionStr];
}



//==============================================================================
- (NSString *) fmdbQueryFromCompoundPredicate:(NSCompoundPredicate *)compoundPredicate
                                       entity:(in NSEntityDescription *)entity
                                       values:(out NSArray **)queryValues
                                  shouldBreak:(out BOOL *)shouldBreak {
        
    //Обработка NOT predicate
    if (compoundPredicate.compoundPredicateType == NSNotPredicateType) {
        // ошибка если подпредикатов != 1?
        NSString* subpredicateString = [self fmdbQueryFromPredicate:[compoundPredicate.subpredicates lastObject]
                                                             entity:entity
                                                             values:queryValues
                                                        shouldBreak:shouldBreak];
        
        return [NSString stringWithFormat:@"NOT (%@)", subpredicateString];
    }
        
    //Обработка AND и OR
    //По документации, если compoundPredicate.subpredicates.count == 0 возвращать TRUE для NSAndPredicateType и FALSE для NSOrPredicateType    
    NSString *predicateTypeString = nil;
    switch (compoundPredicate.compoundPredicateType) {
        case NSAndPredicateType:
            
            if (compoundPredicate.subpredicates.count == 0) {
                return @"(TRUE)";
            }
            
            predicateTypeString = @" AND ";
            
            break;
            
        case NSOrPredicateType:
            
            if (compoundPredicate.subpredicates.count == 0) {
                return @"(FALSE)";
            }
            
            predicateTypeString = @" OR ";
            break;
            
        default:
            
            //TODO: ошибка
            
            break;
    }
    
    
    NSMutableArray *compoundPredicateQueryValues = [NSMutableArray array];
    NSMutableArray *subpredicateStrings = [NSMutableArray arrayWithCapacity:compoundPredicate.subpredicates.count];
    
    for (NSPredicate *subpredicate in compoundPredicate.subpredicates) {
        
        NSArray *subpredicateQueryValues = nil;
        NSString* subpredicateString = [NSString stringWithFormat:@"(%@)", [self fmdbQueryFromPredicate:subpredicate
                                                                                                 entity:entity
                                                                                                 values:&subpredicateQueryValues
                                                                                            shouldBreak:shouldBreak]];
        
        if (subpredicateQueryValues)
            [compoundPredicateQueryValues addObjectsFromArray:subpredicateQueryValues];
        
        [subpredicateStrings addObject:subpredicateString];
    }
    
    *queryValues = compoundPredicateQueryValues.count > 0 ? compoundPredicateQueryValues : nil;
    
    return [subpredicateStrings componentsJoinedByString:predicateTypeString];    
}







////////////////////////////////////////////////////////////////////////////////
#pragma mark - Support methods
////////////////////////////////////////////////////////////////////////////////

- (NSString *) expStringFromExpression:(NSExpression *)expression
                                entity:(NSEntityDescription *)entity
                             putValues:(in NSMutableArray *)expressionsValues
                           shouldBreak:(out BOOL *)shouldBreak {
    
    NSString *expressionStr = nil;
    
    switch (expression.expressionType) {
            
            
        case NSConstantValueExpressionType: {
            
            id expConstantValue = expression.constantValue;
            
            [self transformConstantValue:expConstantValue
                             toExpValues:expressionsValues
                      andExpFormatString:&expressionStr
                             shouldBreak:shouldBreak];
        }
            break;
            
            
            
        case NSKeyPathExpressionType:
            
            if (entity) {
                
                NSPropertyDescription *pDesc = [entity.propertiesByName valueForKey:expression.keyPath];
                expressionStr = [pDesc.userInfo valueForKey:kMIStoreAttributeName] ?: [expression.keyPath lowercaseString];
                
            }
            else {
                
                expressionStr = [expression.keyPath lowercaseString];
                
            }
            break;
            
           
            
        case NSEvaluatedObjectExpressionType:
            
            expressionStr = [entity.userInfo valueForKey:kMIStoreRowIdField] ?: @"rowId";
            
            break;
            
            
            
        case NSFunctionExpressionType: {
            
            NSExpression *operand = [expression operand];
            id expValue = [expression expressionValueWithObject:operand context:nil];
            
            [self transformConstantValue:expValue
                             toExpValues:expressionsValues
                      andExpFormatString:&expressionStr
                             shouldBreak:shouldBreak];
        }
            break;
            
            
        default:
            
            //    NSConstantValueExpressionType = 0, // Expression that always returns the same value
            //    NSEvaluatedObjectExpressionType, // Expression that always returns the parameter object itself
            //    NSVariableExpressionType, // Expression that always returns whatever is stored at 'variable' in the bindings dictionary
            //    NSKeyPathExpressionType, // Expression that returns something that can be used as a key path
            //    NSUnionSetExpressionType NS_ENUM_AVAILABLE(10_5, 3_0), // Expression that returns the result of doing a unionSet: on two expressions that evaluate to flat collections (arrays or sets)
            //    NSIntersectSetExpressionType NS_ENUM_AVAILABLE(10_5, 3_0), // Expression that returns the result of doing an intersectSet: on two expressions that evaluate to flat collections (arrays or sets)
            //    NSMinusSetExpressionType NS_ENUM_AVAILABLE(10_5, 3_0), // Expression that returns the result of doing a minusSet: on two expressions that evaluate to flat collections (arrays or sets)
            //    NSSubqueryExpressionType NS_ENUM_AVAILABLE(10_5, 3_0) = 13,
            //    NSAggregateExpressionType NS_ENUM_AVAILABLE(10_5, 3_0)
            
            
            break;
    }
    
    return expressionStr;
}


//==============================================================================
//Обработка константного значения из expression-а. На вход поступает значение, полученное из expressio-а, внутри метода оно преобразуется необходимым образом. Метод возвращает строку-формат SQL-выражения.
- (void) transformConstantValue:(in id)expConstantValue
                    toExpValues:(out NSMutableArray *)expressionValues
             andExpFormatString:(out NSString **)expressionStr
                    shouldBreak:(out BOOL *)shouldBreak {
    
    //Если сравниваем с конкретным значением...
    if (expConstantValue) {
        
        if (expressionStr != NULL)
                *expressionStr = @"?";
        
        if ([expConstantValue isKindOfClass:[NSDate class]]) {
            NSDate *dateToCompare =  (NSDate *)expConstantValue;
            expConstantValue = @((int)[dateToCompare timeIntervalSince1970]);
            
            [expressionValues addObject:expConstantValue];
        }
        
        else if ([expConstantValue isKindOfClass:[NSArray class]]) {
            
            NSArray *expArray = (NSArray *)expConstantValue;
            
            NSMutableArray *queryFormats = [NSMutableArray arrayWithCapacity:[expArray count]];
            NSMutableArray *queryValues = [NSMutableArray arrayWithCapacity:[expArray count]];
            
            for (id nextObject in expArray) {
                
                //Преобразуем NSManagedObjectID в массив значений referenceObject-а
                if ([[expArray lastObject] isKindOfClass:[NSManagedObjectID class]]) {
                    
                    NSManagedObjectID *nextObjectID = (NSManagedObjectID *)nextObject;
                    
                    //Другие persistenStore-ы не поддерживаютcя
                    if (![nextObjectID.persistentStore isKindOfClass:[NSIncrementalStore class]]) {
 
                        /*
                            NOTE: в такой ситуации не стоит делать запрос вовсе, поскольку ясное дело - ничего не найдётся
                         */
                        *shouldBreak = YES;
                        continue;
                    };
                    
                    //уникальный идентификатор выбираемого объекта.
                    id rowId = [(NSIncrementalStore *)nextObjectID.persistentStore referenceObjectForObjectID:nextObjectID];
                    
                    [queryValues addObject:rowId];
                }
                else {
                    
                    [queryValues addObject:nextObject];
                }
                
                [queryFormats addObject:@" ? "];
            }
            
            if (expressionStr != NULL)
                    *expressionStr = [NSString stringWithFormat:@"( %@ )",[queryFormats componentsJoinedByString:@","]];
            
            [expressionValues addObjectsFromArray:queryValues];
        }
        
        else {
            [expressionValues addObject:expConstantValue];
        }
    }
    
    //Если сравниваем с nil-ом...
    else {
        
        if (expressionStr != NULL)
                *expressionStr = @"NULL";
    }
}


@end

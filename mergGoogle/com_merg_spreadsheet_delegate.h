//
//  com_merg_spreadsheet_delegate.h
//  mergGoogle
//
//  Created by Monte Goulding on 27/07/2015.
//
//

#import <Foundation/Foundation.h>
#import <LiveCode.h>
#if TARGET_OS_IPHONE
#import "GTMOAuth2ViewControllerTouch.h"
#import "GData.h"
#else
#import <GData/GTMOAuth2WindowController.h>
#import <GData/GData.h>
#endif

@interface com_merg_spreadsheet_delegate : NSObject
{
    LCObjectRef me;
    GDataServiceGoogleSpreadsheet* _service;
    bool isFetchingSpreadsheets;
    
    NSArray * _spreadsheets;
    bool isFetchingWorksheets;
    NSMutableArray * _worksheets;
    NSString * _lastFetchedSpreadsheetID;
    bool isFetchingCells;
    NSMutableArray * _cells;
    NSString * _lastFetchedWorksheetID;
    NSString * _lastDeletedWorksheetID;
    
}

@property (readonly, nonatomic) bool isFetchingSpreadsheets;
@property (readonly, nonatomic) bool isFetchingWorksheets;
@property (readonly, nonatomic) bool isFetchingCells;

- (void) auth:(GTMOAuth2Authentication *) auth;

- (bool) isAuthorized;
- (void) fetchSpreadsheetFeed;
- (void) fetchWorksheetFeed: (NSString *) identifier;
- (void) fetchCellFeed: (NSString *) identifier;
- (void) setValueForWorksheet:(NSString *) resourceID column:(int) column row: (int) row value: (NSString *) value;
- (NSString *) getValueForCellColumn:(int) column row: (int) row input: (bool) input;
- (void) createWorksheet:(NSString *) identifier titled:(NSString *)pTitle columns:(int)column rows:(int)row;
- (void) updateWorksheet:(NSString *) identifier titled:(NSString *)pTitle columns:(int)column rows:(int)row;
- (void) deleteWorksheet:(NSString *) identifier;
- (NSString *) getAllCellValues: (bool) input;
@end

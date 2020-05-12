//
//  mergGoogle.mm
//  mergGoogle
//
//  Created by Monte Goulding on 27/07/2015.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
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
#import "com_merg_oauth_delegate.h"
#import "com_merg_spreadsheet_delegate.h"

static NSMutableArray * s_auth = nil;

NSString * mergGoogleAuth(NSString * pScope, NSString * pClient, NSString * pSecret, NSString * pKeychainItemName)
{
    
    if ([pSecret isEqualToString:@""])
        pSecret = nil;
    
    // First check the keychain
    
    GTMOAuth2Authentication *auth = nil;
    
#if TARGET_OS_IPHONE
    auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:pKeychainItemName
                                                                 clientID:pClient
                                                             clientSecret:pSecret];
#else
    auth = [GTMOAuth2WindowController authForGoogleFromKeychainForName:pKeychainItemName
                                                                 clientID:pClient
                                                             clientSecret:pSecret];
#endif
    
    if (![auth canAuthorize])
    {
    
        LCWaitRef t_wait;
        LCWaitCreate(kLCWaitOptionDispatching, &t_wait);
        
        com_merg_oauth_delegate * t_delegate = [[[com_merg_oauth_delegate alloc] initWithWait:t_wait] autorelease];
        [t_delegate runWithScope:pScope clientID:pClient secret:pSecret keychainItemName:pKeychainItemName];
        
        if ([t_delegate error] != nil)
            return [[t_delegate error] localizedDescription];
        
        auth = [t_delegate auth];
    }
    
    if (s_auth == nil)
        s_auth = [[NSMutableArray array] retain];
    
    if (auth != nil)
    {
        [s_auth addObject:auth];
        return [NSString stringWithFormat:@"%ld",(unsigned long)[s_auth count]];
    }
    
    return @"unknown error";
}

static com_merg_spreadsheet_delegate * s_spreadsheet_delegate = nil;

void ensureSpreadsheetDelegate(void)
{
    if (s_spreadsheet_delegate == nil)
        s_spreadsheet_delegate = [[com_merg_spreadsheet_delegate alloc] init];
}

void mergGoogleSpreadsheetsInitialize(int pAuth)
{
    ensureSpreadsheetDelegate();
    
    GTMOAuth2Authentication * t_auth = (GTMOAuth2Authentication *)[s_auth objectAtIndex:pAuth-1];
    if (t_auth == nil)
    {
        LCExceptionRaise("auth not found");
        return;
    }
    
    [s_spreadsheet_delegate auth:t_auth];
}

void mergGoogleLoadSpreadsheets(void)
{
    ensureSpreadsheetDelegate();
    if (![s_spreadsheet_delegate isAuthorized])
    {
        LCExceptionRaise("you must set the auth token with mergGoogleSpreadsheetsInitialize");
        return;
    }
    
    if ([s_spreadsheet_delegate isFetchingSpreadsheets])
    {
        LCExceptionRaise("currently loading data");
        return;
    }
    
    [s_spreadsheet_delegate fetchSpreadsheetFeed];
}

void mergGoogleLoadWorksheets(NSString * pSpreadsheet)
{
    ensureSpreadsheetDelegate();
    if (![s_spreadsheet_delegate isAuthorized])
    {
        LCExceptionRaise("you must set the auth token with mergGoogleSpreadsheetsInitialize");
        return;
    }
    
    if ([s_spreadsheet_delegate isFetchingSpreadsheets] || [s_spreadsheet_delegate isFetchingWorksheets])
    {
        LCExceptionRaise("currently loading data");
        return;
    }
    
    [s_spreadsheet_delegate fetchWorksheetFeed:pSpreadsheet];
}

void mergGoogleCreateWorksheet(NSString * pTitle, NSString * pSpreadsheet, int pColumns, int pRows)
{
    ensureSpreadsheetDelegate();
    if (![s_spreadsheet_delegate isAuthorized])
    {
        LCExceptionRaise("you must set the auth token with mergGoogleSpreadsheetsInitialize");
        return;
    }
    
    if ([s_spreadsheet_delegate isFetchingSpreadsheets] || [s_spreadsheet_delegate isFetchingWorksheets])
    {
        LCExceptionRaise("currently loading data");
        return;
    }
    
    [s_spreadsheet_delegate createWorksheet:pSpreadsheet titled:pTitle columns:pColumns rows:pRows];

}

void mergGoogleUpdateWorksheet(NSString * pTitle, NSString * pWorksheet, int pColumns, int pRows)
{
    ensureSpreadsheetDelegate();
    if (![s_spreadsheet_delegate isAuthorized])
    {
        LCExceptionRaise("you must set the auth token with mergGoogleSpreadsheetsInitialize");
        return;
    }
    
    if ([s_spreadsheet_delegate isFetchingSpreadsheets] || [s_spreadsheet_delegate isFetchingWorksheets])
    {
        LCExceptionRaise("currently loading data");
        return;
    }
    
    [s_spreadsheet_delegate updateWorksheet:pWorksheet titled:pTitle columns:pColumns rows:pRows];
    
}



void mergGoogleDeleteWorksheet(NSString * pWorksheet)
{
    ensureSpreadsheetDelegate();
    if (![s_spreadsheet_delegate isAuthorized])
    {
        LCExceptionRaise("you must set the auth token with mergGoogleSpreadsheetsInitialize");
        return;
    }
    
    [s_spreadsheet_delegate deleteWorksheet:pWorksheet];
}

void mergGoogleLoadCells(NSString * pWorksheet)
{
    ensureSpreadsheetDelegate();
    if (![s_spreadsheet_delegate isAuthorized])
    {
        LCExceptionRaise("you must set the auth token with mergGoogleSpreadsheetsInitialize");
        return;
    }
    
    if ([s_spreadsheet_delegate isFetchingSpreadsheets] || [s_spreadsheet_delegate isFetchingWorksheets] || [s_spreadsheet_delegate isFetchingCells])
    {
        LCExceptionRaise("currently loading data");
        return;
    }
    
    [s_spreadsheet_delegate fetchCellFeed:pWorksheet];
}

NSString * mergGoogleGetValueForCell(int row, int column, bool input)
{
    ensureSpreadsheetDelegate();
    if (![s_spreadsheet_delegate isAuthorized])
    {
        LCExceptionRaise("you must set the auth token with mergGoogleSpreadsheetsInitialize");
        return @"";
    }
    
    NSString * t_value = [s_spreadsheet_delegate getValueForCellColumn:column row:row input:input];
    if (t_value == nil)
        t_value = @"";
    
    return t_value;
}

void mergGoogleSetValueForCell(int row, int column, NSString * pValue, NSString * pWorksheet)
{
    ensureSpreadsheetDelegate();
    if (![s_spreadsheet_delegate isAuthorized])
    {
        LCExceptionRaise("you must set the auth token with mergGoogleSpreadsheetsInitialize");
        return;
    }
    
    [s_spreadsheet_delegate setValueForWorksheet:pWorksheet column:column row:row value:pValue];
}

NSString * mergGoogleGetAllCellValues(bool input)
{
    ensureSpreadsheetDelegate();
    if (![s_spreadsheet_delegate isAuthorized])
    {
        LCExceptionRaise("you must set the auth token with mergGoogleSpreadsheetsInitialize");
        return @"";
    }
    
    NSString * t_value = [s_spreadsheet_delegate getAllCellValues:input];
    if (t_value == nil)
        t_value = @"";
    
    return t_value;
}

#pragma mark Hooks

// This handler is called when the external is loaded. We use it to set all our
// static locals to default values.
bool mergGoogleStartup(void)
{
    // Ensure external can only be used in Indy standalones
    LCLicenseCheckEdition(kLCLicenseEditionIndy);
    
    return true;
}
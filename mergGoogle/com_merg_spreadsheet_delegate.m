//
//  com_merg_spreadsheet_delegate.m
//  mergGoogle
//
//  Created by Monte Goulding on 27/07/2015.
//
//

#import "com_merg_spreadsheet_delegate.h"

@implementation com_merg_spreadsheet_delegate

@synthesize isFetchingCells;
@synthesize isFetchingSpreadsheets;
@synthesize isFetchingWorksheets;

- (id) init
{
    [super init];
    
    _service = nil;
    isFetchingSpreadsheets = false;
    isFetchingWorksheets = false;
    isFetchingCells = false;
    
    LCContextMe(&me);
    
    return self;
}

- (void)dealloc
{
    [_service release];
    
    [super dealloc];
}



- (void) auth:(GTMOAuth2Authentication *) auth
{
    if (!_service) {
        _service = [[GDataServiceGoogleSpreadsheet alloc] init];
       [_service setShouldCacheResponseData:YES];
       [_service setServiceShouldFollowNextLinks:YES];
       [_service setAuthorizer:auth];
   }

}

- (bool) isAuthorized
{
    return [((GTMOAuth2Authentication *) _service.authorizer) canAuthorize];
}

- (void) fetchSpreadsheetFeed
{
    if (_service)
    {
        if (! isFetchingSpreadsheets)
        {
            isFetchingSpreadsheets = true;
            
            NSURL *feedURL = [NSURL URLWithString:kGDataGoogleSpreadsheetsPrivateFullFeed];
            [_service fetchFeedWithURL:feedURL
                             delegate:self
                    didFinishSelector:@selector(spreadsheetFeedTicket:finishedWithFeed:error:)];
        }
    }

}


// spreadsheet list fetch callback
- (void)spreadsheetFeedTicket:(GDataServiceTicket *)ticket
  finishedWithFeed:(GDataFeedSpreadsheet *)feed
             error:(NSError *)error {
    
    isFetchingSpreadsheets = false;
    
    if (error != nil)
        LCObjectPost(me, "mergGoogleLoadSpreadsheetsError", "S", error.localizedDescription);
    else
    {
    
        if (_spreadsheets != nil)
            [_spreadsheets release];
        _spreadsheets = [feed entries];
        
        [_spreadsheets retain];
        
        NSMutableArray * t_array = [NSMutableArray array];
        for (GDataEntrySpreadsheet * t_spreadsheet in _spreadsheets) {
            [t_array addObject:[NSString stringWithFormat:@"%@\t%@", t_spreadsheet.identifier, t_spreadsheet.title.stringValue]];
        }
        LCObjectPost(me, "mergGoogleSpreadsheetsLoaded", "S", [t_array componentsJoinedByString:@"\n"]);
    }
    
}

- (void) fetchWorksheetFeed: (NSString *) identifier
{
    if (_service)
    {
        if ([identifier isEqualToString:@""])
            identifier = _lastFetchedSpreadsheetID;
        
        if (identifier != nil)
        {
            for (GDataEntrySpreadsheet * t_spreadsheet in _spreadsheets) {
                if ([t_spreadsheet.identifier isEqualToString:identifier])
                {
                    if (_lastFetchedSpreadsheetID != nil)
                        [_lastFetchedSpreadsheetID release];
                        _lastFetchedSpreadsheetID = identifier;
                    [_lastFetchedSpreadsheetID retain];
                    
                    NSLog(@"spreadsheet: %@",t_spreadsheet);
                    
                    NSURL *feedURL = [t_spreadsheet worksheetsFeedURL];
                    if (feedURL)
                    {
                        isFetchingWorksheets = true;
                        
                        
                        [_service fetchFeedWithURL:feedURL
                                      delegate:self
                             didFinishSelector:@selector(worksheetsTicket:finishedWithFeed:error:)];
                    }
                }
            }
        }
    }
    
}

// fetch worksheet feed callback
- (void)worksheetsTicket:(GDataServiceTicket *)ticket
        finishedWithFeed:(GDataFeedWorksheet *)feed
                   error:(NSError *)error {
    
    
    isFetchingWorksheets = false;

    if (error != nil)
        LCObjectPost(me, "mergGoogleLoadWorksheetsError", "SS", _lastFetchedSpreadsheetID, error.localizedDescription);
    else
    {
        
        if (_worksheets != nil)
            [_worksheets release];
        
        _worksheets = [[feed entries] mutableCopy];
        [_worksheets retain];
        
        NSMutableArray * t_array = [NSMutableArray array];
        for (GDataEntryWorksheet * t_worksheet in _worksheets) {
            [t_array addObject:[NSString stringWithFormat:@"%@\t%@\t%ld\t%ld", t_worksheet.identifier, t_worksheet.title.stringValue, (long)t_worksheet.columnCount, (long)t_worksheet.rowCount]];
        }
        LCObjectPost(me, "mergGoogleWorksheetsLoaded", "SS", _lastFetchedSpreadsheetID, [t_array componentsJoinedByString:@"\n"]);
    }
    
}

- (void) fetchCellFeed: (NSString *) identifier
{
    
    if (_service)
    {
        if ([identifier isEqualToString:@""])
            identifier = _lastFetchedWorksheetID;
        
        if (identifier != nil)
        {
            for (GDataEntryWorksheet * t_worksheet in _worksheets) {
                if ([t_worksheet.identifier isEqualToString:identifier])
                {
                    if (_lastFetchedWorksheetID != nil)
                        [_lastFetchedWorksheetID release];
                    _lastFetchedWorksheetID = identifier;
                    [_lastFetchedWorksheetID retain];
                    
                    NSURL *feedURL = [[t_worksheet cellsLink] URL];
                    if (feedURL)
                    {
                        isFetchingCells = true;
                        
                        [_service fetchFeedWithURL:feedURL
                                          delegate:self
                                 didFinishSelector:@selector(entriesTicket:finishedWithFeed:error:)];
                    }
                }
            }
        }
    }
}

// fetch entries callback
- (void)entriesTicket:(GDataServiceTicket *)ticket
     finishedWithFeed:(GDataFeedSpreadsheetCell *)feed
                error:(NSError *)error {
    
    isFetchingCells = false;
    
    if (error != nil)
        LCObjectPost(me, "mergGoogleLoadCellsError", "SS", _lastFetchedWorksheetID , error.localizedDescription);
    else
    {
        
        if (_cells != nil)
            [_cells release];
        
        _cells = [[feed entries] mutableCopy];
        [_cells retain];
        
        LCObjectPost(me, "mergGoogleCellsLoaded", "Si", _lastFetchedWorksheetID, [_cells count]);
    }

    
}

- (void) setValueForWorksheet:(NSString *) identifier column:(int) column row: (int) row value: (NSString *) value
{
    
    if ([identifier isEqualToString:@""])
        identifier = _lastFetchedWorksheetID;
    
    if (identifier != nil)
    {
    
        for (GDataEntryWorksheet * t_worksheet in _worksheets) {
            if ([t_worksheet.identifier isEqualToString:identifier])
            {
                
                NSNumberFormatter *t_formatter = [[NSNumberFormatter alloc] init];
                t_formatter.numberStyle = NSNumberFormatterDecimalStyle;
                NSNumber *t_numericValue = [t_formatter numberFromString:value];
                [t_formatter release];
                
                GDataSpreadsheetCell * t_cell = [GDataSpreadsheetCell cellWithRow:row column:column inputString:value numericValue:t_numericValue resultString:nil];
                
                // create a cellEntry object that will contain the cell
                GDataEntrySpreadsheetCell * t_cellEntry = [GDataEntrySpreadsheetCell spreadsheetCellEntryWithCell:t_cell];
                
                // upload the cellEntry to your spreadsheet
                [_service fetchEntryByInsertingEntry:t_cellEntry
                                          forFeedURL: [[t_worksheet cellsLink] URL]
                                            delegate:self
                                   didFinishSelector:@selector(setValueTicket:finishedWithEntry:error:)];

                
            }
        }
        
    }

    
}

- (void)setValueTicket:(GDataServiceTicket *)ticket
            finishedWithEntry:(GDataEntrySpreadsheetCell *)entry
                        error:(NSError *)error {
    
    if (error != nil)
        LCObjectPost(me, "mergGoogleSetCellValueError", "S", error.localizedDescription);
    else
    {
        int i = 0;
        bool t_found = false;
        for (GDataEntrySpreadsheetCell * t_cell in _cells)
        {
            if ([[t_cell cell] column] == [[entry cell] column] && [[t_cell cell] row] == [[entry cell] row])
            {
                t_found = true;
                break;
            }
            i++;
        }
        
        if (t_found)
            [_cells replaceObjectAtIndex:i withObject:entry];
        else
            [_cells addObject:entry];

        LCObjectPost(me, "mergGoogleCellValueSet", "ii", [[entry cell] column], [[entry cell] row]);
    }
}

- (NSString *) getAllCellValues: (bool) input
{
    NSMutableArray * rows = [NSMutableArray array];
    if (_cells != nil)
    {
        GDataEntryWorksheet * t_worksheet;
        for (t_worksheet in _worksheets) {
            if ([t_worksheet.identifier isEqualToString:_lastFetchedWorksheetID])
            {
                break;
            }
        }
        
        NSInteger columnCount = t_worksheet.columnCount;
        NSInteger rowCount = t_worksheet.rowCount;
        
        if (columnCount == 0 || rowCount == 0)
        {
            for (GDataEntrySpreadsheetCell * t_cell in _cells)
            {
                if ([[t_cell cell] column] > columnCount)
                    columnCount = [[t_cell cell] column];
                
                if ([[t_cell cell] row] > rowCount)
                    columnCount = [[t_cell cell] row];
            }
        }
        
        // setup template sheet
        for (NSInteger row = 0; row <= rowCount; row++)
        {
            NSMutableArray * columns = [NSMutableArray array];
            for (NSInteger column = 0; column <= columnCount; column++)
            {
                [columns addObject:@""];
            }
            [rows addObject:columns];
        }
        
        for (GDataEntrySpreadsheetCell * t_cell in _cells)
        {
            NSString * t_value = nil;
            if (input && [[t_cell cell] inputString] != nil)
                t_value = [[t_cell cell] inputString];
            
            if (t_value == nil)
            {
                if ([[t_cell cell] numericValue] != nil)
                    t_value = [NSString stringWithFormat:@"%@",[[t_cell cell] numericValue]];
                else if ([[t_cell cell] resultString] != nil)
                    t_value = [[t_cell cell] resultString];
            }
            
            NSInteger row, column;
            row = [[t_cell cell] row]-1;
            column = [[t_cell cell] column]-1;
            
            [((NSMutableArray *) rows[row]) replaceObjectAtIndex:column withObject:t_value];
        }
    }
    
    NSMutableArray * result = [NSMutableArray array];
    
    for (NSMutableArray * columns in rows)
        [result addObject:[columns componentsJoinedByString:@"\t"]];
    
    return [result componentsJoinedByString:@"\n"];
}

- (NSString *) getValueForCellColumn:(int) column row: (int) row input: (bool) input
{
    NSString * t_value = nil;
    if (_cells != nil)
    {
        for (GDataEntrySpreadsheetCell * t_cell in _cells)
        {
            if ([[t_cell cell] column] == column && [[t_cell cell] row] == row)
            {
                if (t_value == nil)
                {
                    if (input && [[t_cell cell] inputString] != nil)
                        t_value = [[t_cell cell] inputString];
                    
                    if (t_value == nil)
                    {
                        if ([[t_cell cell] numericValue] != nil)
                            t_value = [NSString stringWithFormat:@"%@",[[t_cell cell] numericValue]];
                        else if ([[t_cell cell] resultString] != nil)
                            t_value = [[t_cell cell] resultString];
                    }
                }
                break;
            }
        }
    }
    
    return t_value;
}

- (void) createWorksheet:(NSString *) identifier titled: (NSString *)pTitle columns:(int)column rows:(int)row
{
    
    
    if (_service)
    {
        if ([identifier isEqualToString:@""])
            identifier = _lastFetchedSpreadsheetID;
        
        if (identifier != nil)
        {
            for (GDataEntrySpreadsheet * t_spreadsheet in _spreadsheets) {
                if ([t_spreadsheet.identifier isEqualToString:identifier])
                {
                    
                    NSURL *feedURL = [t_spreadsheet worksheetsFeedURL];
                    if (feedURL)
                    {
                        GDataEntryWorksheet * t_worksheet = [GDataEntryWorksheet worksheetEntry];
                        [t_worksheet setTitle:[GDataTextConstruct textConstructWithString:pTitle]];
                        if (column > 0)
                            [t_worksheet setColumnCount:column];
                        if (row > 0)
                            [t_worksheet setRowCount:row];
                        
                        [_service fetchEntryByInsertingEntry:t_worksheet forFeedURL:feedURL
                                          delegate:self
                                 didFinishSelector:@selector(createWorksheetTicket:finishedWithEntry:error:)];
                    }
                }
            }
        }
        
    }

    
}

- (void)createWorksheetTicket:(GDataServiceTicket *)ticket
     finishedWithEntry:(GDataEntryWorksheet *)entry
                error:(NSError *)error {
    
    if (error != nil)
        LCObjectPost(me, "mergGoogleCreateWorksheetError", "S", error.localizedDescription);
    else
    {
        [_worksheets addObject:entry];
        LCObjectPost(me, "mergGoogleWorksheetCreated", "S", [entry identifier]);
    }
 }


- (void) updateWorksheet:(NSString *) identifier titled: (NSString *)pTitle columns:(int)column rows:(int)row
{
    
    
    if (_service)
    {
        if ([identifier isEqualToString:@""])
            identifier = _lastFetchedWorksheetID;
        
        if (identifier != nil)
        {
            for (GDataEntryWorksheet * t_worksheet in _worksheets) {
                if ([t_worksheet.identifier isEqualToString:identifier])
                {
                    
                    [t_worksheet setTitle:[GDataTextConstruct textConstructWithString:pTitle]];
                    if (column > 0)
                        [t_worksheet setColumnCount:column];
                    if (row > 0)
                        [t_worksheet setRowCount:row];
                    [_service fetchEntryByUpdatingEntry:t_worksheet completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) {
                        
                        if (error != nil)
                        {
                            LCObjectPost(me, "mergGoogleUpdateWorksheetError", "S", error.localizedDescription);
                        }
                        else
                        {
                            int t_count = 0;
                            bool t_found = false;
                            for (GDataEntryWorksheet * t_worksheet in _worksheets) {
                                if ([t_worksheet.identifier isEqualToString:entry.identifier])
                                {
                                    t_found = true;
                                    break;
                                }
                                if (t_found)
                                    [_worksheets replaceObjectAtIndex:t_count withObject:entry];
                                
                                t_count++;
                            }
                            
                            LCObjectPost(me, "mergGoogleWorksheetUpdated", "S", [entry identifier]);
                        }
                    }];
                    
                }
            }
        }
        
    }
    
    
}


- (void) deleteWorksheet:(NSString *) identifier
{
    if ([identifier isEqualToString:@""])
        identifier = _lastFetchedWorksheetID;
    
    if (identifier != nil)
    {
        
        _lastDeletedWorksheetID = [NSString stringWithString:identifier];
        for (GDataEntryWorksheet * t_worksheet in _worksheets) {
            if ([t_worksheet.identifier isEqualToString:identifier])
            {
                GDataServiceTicket *ticket = [_service deleteEntry:t_worksheet delegate:self didFinishSelector:@selector(deleteWorksheetTicket:finishedWithEntry:error:)];
                [ticket setProperty:identifier forKey:@"deleted_worksheet_identifier"];
            }
        }
    }
}

- (void)deleteWorksheetTicket:(GDataServiceTicket *)ticket
            finishedWithEntry:(GDataEntryWorksheet *)entry
                        error:(NSError *)error {
    NSString * t_identifier = [ticket propertyForKey:@"deleted_worksheet_identifier"];
    if (error != nil)
        LCObjectPost(me, "mergGoogleDeleteWorksheetError", "SS", t_identifier, error.localizedDescription);
    else
    {
        int i = 0;
        bool t_found = false;
        for (GDataEntryWorksheet * t_worksheet in _worksheets) {
            if ([t_worksheet.identifier isEqualToString:t_identifier])
            {
                t_found = true;
                break;
            }
            i++;
        }
        
        if (t_found)
            [_worksheets removeObjectAtIndex:i];;
        
        LCObjectPost(me, "mergGoogleWorksheetDeleted", "S", t_identifier);
    }
}


@end

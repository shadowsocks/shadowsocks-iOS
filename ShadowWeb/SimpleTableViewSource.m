//
// Created by clowwindy on 6/6/13.
// Copyright (c) 2013 clowwindy. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "SimpleTableViewSource.h"


@implementation SimpleTableViewSource {
    NSArray *_labels;
    NSArray *_values;
    NSObject *_value;
    SimpleTableViewSourceSelectionBlock _selectionBlock;
}

- (id)initWithLabels:(NSArray *)labels values:(NSArray *)values initialValue:(NSObject *)value selectionBlock:(SimpleTableViewSourceSelectionBlock)block {
    self = [super init];
    if (self) {
        _labels = labels;
        _values = values;
        _value = value;
        _selectionBlock = block;
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = _labels[indexPath.row];
    NSObject *currentValue = _values[indexPath.row];
    if (currentValue == _value || [currentValue isEqual:_value]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else{
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _labels.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int newRow = [indexPath row];
    _value = _values[newRow];
    int rowCount = [tableView numberOfRowsInSection:0];
    for (int i = 0; i<rowCount; i++) {
        if (i != newRow) {
            [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]].accessoryType = UITableViewCellAccessoryNone;
        }
    }
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    _selectionBlock(_value);
}


@end
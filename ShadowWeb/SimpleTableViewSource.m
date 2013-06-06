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
    SimpleTableViewSourceSelectionBlock _selectionBlock;
}

- (id)initWithLabels:(NSArray *)labels values:(NSArray *)values selectionBlock:(SimpleTableViewSourceSelectionBlock)block {
    _labels = labels;
    _values = values;
    _selectionBlock = block;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}


@end

/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "MapHomeViewController.h"

@interface ReunionMapHomeViewController : MapHomeViewController {
    
    BOOL _didSetRegion;
    MKCoordinateRegion _endRegion;
}

@property (nonatomic) MKCoordinateRegion startRegion;
@property (nonatomic) MKCoordinateRegion endRegion;
@property (nonatomic) CGRect startFrame;

@end

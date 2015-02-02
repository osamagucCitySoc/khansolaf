//
//  MatchLocationViewController.m
//  speeddate
//
//  Created by STUDIO76 on 08.09.14.
//  Copyright (c) 2014 studio76. All rights reserved..
//

#import "MatchLocationViewController.h"
#import "SWRevealViewController.h"
#import "UserParseHelper.h"
#import <MapKit/MapKit.h>

@interface MatchLocationViewController () <MKMapViewDelegate, CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sideBarButton;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *switchButton;
@property (weak, nonatomic) IBOutlet UISwitch *theSwitch;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UIButton *centerButton;
@property (weak, nonatomic) IBOutlet UIButton *arrowButton;
@property UserParseHelper* curUser;
@property BOOL switchCurrentLocation;
@property CLLocation* currentLocation;
@property (weak, nonatomic) IBOutlet UISlider *sliderRadius;
@property CLLocationManager* locationManager;
@end

@implementation MatchLocationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _sideBarButton.target = self.revealViewController;
    _sideBarButton.action = @selector(revealToggle:);
    self.theSwitch.userInteractionEnabled = NO;

    self.mapView.scrollEnabled = NO;
    self.centerButton.backgroundColor = RED_LIGHT;
    UIView* backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 53, self.view.frame.size.width, 40)];
    backgroundView.backgroundColor = WHITE_COLOR;
    backgroundView.alpha = 0.7;
    backgroundView.clipsToBounds = YES;
    [self.view addSubview:backgroundView];
    [self.view sendSubviewToBack:backgroundView];
    [self.view sendSubviewToBack:self.mapView];
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 20)];
    self.searchTextField.leftView = paddingView;
    self.searchTextField.leftViewMode = UITextFieldViewModeAlways;
    self.searchTextField.backgroundColor = RED_DEEP;
    self.distanceLabel.textColor = RED_LIGHT;
    self.sliderRadius.tintColor = RED_LIGHT;
    self.sliderRadius.thumbTintColor = RED_LIGHT;
    self.sliderRadius.minimumTrackTintColor = RED_LIGHT;
    self.theSwitch.onTintColor = RED_LIGHT;
    self.mapView.delegate = self;
    PFQuery* curQuery = [UserParseHelper query];
    [curQuery whereKey:@"username" equalTo:[UserParseHelper currentUser].username];
    [curQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.curUser = objects.firstObject;
        [self.sliderRadius setValue:self.curUser.distance.floatValue];
        self.distanceLabel.text = [NSString stringWithFormat:@"%dkm",(int)self.sliderRadius.value];
        [self UserOnMap];
    }];
    // Do any additional setup after loading the view.
}

- (void) UserOnMap
{
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.mapView removeAnnotations:self.mapView.annotations];
    MKCircle* circle = [MKCircle circleWithCenterCoordinate:CLLocationCoordinate2DMake(self.curUser.geoPoint.latitude, self.curUser.geoPoint.longitude) radius:self.curUser.distance.doubleValue*1000];
    MKPointAnnotation* annotation = [MKPointAnnotation new];
    annotation.coordinate = CLLocationCoordinate2DMake(self.curUser.geoPoint.latitude, self.curUser.geoPoint.longitude);
    [self.mapView addAnnotation:annotation];
    [self.mapView addOverlay:circle];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(self.curUser.geoPoint.latitude, self.curUser.geoPoint.longitude), self.curUser.distance.doubleValue*2100, self.curUser.distance.doubleValue*2100);
    [self.mapView setRegion:region];
    [self.mapView reloadInputViews];
    self.searchButton.imageView.image = [UIImage imageNamed:@"magnifying-glass"];
    self.searchButton.userInteractionEnabled = YES;
    self.arrowButton.hidden = NO;
    self.searchTextField.enabled = YES;
    self.searchTextField.textAlignment = NSTextAlignmentCenter;
    self.searchTextField.backgroundColor = RED_DEEP;
    self.searchTextField.textColor = WHITE_COLOR;
    self.searchTextField.text = @"";
    if ([self.curUser.useAddress isEqualToString:@"YES"]) {
        self.switchCurrentLocation = NO;
        self.theSwitch.on = NO;
        self.arrowButton.userInteractionEnabled = YES;
        self.arrowButton.imageView.image = [UIImage imageNamed:@"arrow"];
        self.searchButton.imageView.image = [UIImage imageNamed:@"magnifying-glass"];
        self.centerButton.backgroundColor = RED_DEEP;
        annotation.title = @"موقعك على الخريطة";
        CLGeocoder* geocoder = [CLGeocoder new];
        CLLocation* location = [[CLLocation alloc]initWithLatitude:self.curUser.geoPoint.latitude longitude:self.curUser.geoPoint.longitude];
        [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            CLPlacemark* placemark = placemarks.firstObject;
            UIColor *color = WHITE_COLOR;
            self.searchTextField.attributedPlaceholder =
            [[NSAttributedString alloc]
             initWithString:[NSString stringWithFormat:@"موقع متوافق: %@", placemark.locality]
             attributes:@{NSForegroundColorAttributeName:color}];
            [self.centerButton setTitle:[NSString stringWithFormat:@"موقع متوافق: %@, %@", placemark.locality, placemark.administrativeArea] forState:UIControlStateNormal];
            [self.centerButton setTitleColor:WHITE_COLOR forState:UIControlStateNormal];
            self.centerButton.userInteractionEnabled = YES;
        }];
    } else {
        self.switchCurrentLocation = YES;
        self.theSwitch.on = YES;
        self.arrowButton.userInteractionEnabled = NO;
        self.arrowButton.imageView.image = [UIImage imageNamed:@"arrowOutline"];
        self.centerButton.backgroundColor = RED_LIGHT;
        annotation.title = @"Your Real Location";
        CLGeocoder* geocoder = [CLGeocoder new];
        CLLocation* location = [[CLLocation alloc]initWithLatitude:self.curUser.geoPoint.latitude longitude:self.curUser.geoPoint.longitude];
        [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            CLPlacemark* placemark = placemarks.firstObject;
            UIColor *color = WHITE_COLOR;
            self.searchTextField.attributedPlaceholder =
            [[NSAttributedString alloc]
             initWithString:[NSString stringWithFormat:@"الموقع الحالي: %@", placemark.locality]
             attributes:@{NSForegroundColorAttributeName:color}];
            [self.centerButton setTitle:[NSString stringWithFormat:@"الموقع الحالي: %@, %@", placemark.locality, placemark.administrativeArea] forState:UIControlStateNormal];
            [self.centerButton setTitleColor:WHITE_COLOR forState:UIControlStateNormal];
            self.searchTextField.textAlignment = NSTextAlignmentCenter;
            self.centerButton.userInteractionEnabled = YES;
        }];
    }
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKCircle *circle = (MKCircle *)overlay;
    MKCircleRenderer* render = [[MKCircleRenderer alloc] initWithCircle:circle];
    render.fillColor = RED_LIGHT;
    render.alpha = 0.2;
    return render;
}

-(void)currentLocationIdentifier
{
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.currentLocation = [locations objectAtIndex:0];
    [self.locationManager stopUpdatingLocation];
    self.curUser.geoPoint = [PFGeoPoint geoPointWithLatitude:self.currentLocation.coordinate.latitude longitude:self.currentLocation.coordinate.longitude];
    [self.curUser saveEventually:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [self UserOnMap];
        }
    }];
}

- (IBAction)switchHIt:(id)sender
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    if (self.theSwitch.on) {
        [self currentLocationIdentifier];
        CLGeocoder* geocoder = [CLGeocoder new];
        CLLocation* location = [[CLLocation alloc]initWithLatitude:self.curUser.geoPoint.latitude longitude:self.curUser.geoPoint.longitude];
        [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            CLPlacemark* placemark = placemarks.firstObject;
            self.searchTextField.text = @"";
            self.searchTextField.placeholder = [NSString stringWithFormat:@"الموقع الحالي: %@, %@", placemark.locality, placemark.administrativeArea];
            self.searchTextField.textAlignment = NSTextAlignmentCenter;
        }];
        if ([self.curUser.useAddress isEqualToString:@"YES"]) {
            self.curUser.useAddress = @"NO";
            [self.curUser saveEventually:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [self currentLocationIdentifier];
                }
            }];
        }
    } else {
        self.searchButton.imageView.image = [UIImage imageNamed:@"magnifying-glass"];
        self.searchTextField.enabled = YES;
        self.searchTextField.backgroundColor = GRAY_COLOR;
        self.searchTextField.textColor = WHITE_COLOR;
        self.searchTextField.text = @"";
        self.searchTextField.placeholder = @"أدخل موقعاً للبحث عن أصدقاء من خلاله.";
    }
}

- (IBAction)searchDidEnd:(id)sender
{
    CLGeocoder* geocoder = [CLGeocoder new];
    [geocoder geocodeAddressString:self.searchTextField.text completionHandler:^(NSArray *placemarks, NSError *error) {
        if (!error) {
            CLPlacemark* placemark = placemarks.firstObject;
            self.curUser.geoPoint = [PFGeoPoint geoPointWithLatitude:placemark.location.coordinate.latitude longitude:placemark.location.coordinate.longitude];
            NSLog(@"geo point = %f", self.curUser.geoPoint.latitude);
            self.curUser.useAddress = @"YES";
            [self.curUser saveEventually:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [self UserOnMap];
                }
            }];

        }
    }];
}

- (IBAction)distanceChangeEnd:(UISlider *)sender
{
    self.curUser.distance = [NSNumber numberWithInt:(int)sender.value];
    [self.curUser saveEventually:^(BOOL succeeded, NSError *error) {
        [self UserOnMap];
    }];
}

- (IBAction)distanceChangedOutside:(UISlider *)sender
{
    self.curUser.distance = [NSNumber numberWithInt:(int)sender.value];
    [self.curUser saveEventually:^(BOOL succeeded, NSError *error) {
        [self UserOnMap];
    }];
}

- (IBAction)sliderMoved:(UISlider *)sender
{
    self.distanceLabel.text = [NSString stringWithFormat:@"%dkm",(int)sender.value];

}

- (IBAction)editBegan:(id)sender
{
    self.searchTextField.textAlignment = NSTextAlignmentLeft;
}

- (IBAction)tapCenterButton:(id)sender
{
    self.centerButton.userInteractionEnabled = NO;
    [self UserOnMap];
}

- (IBAction)currentLocationButton:(id)sender
{
    [self currentLocationIdentifier];
    CLGeocoder* geocoder = [CLGeocoder new];
    CLLocation* location = [[CLLocation alloc]initWithLatitude:self.curUser.geoPoint.latitude longitude:self.curUser.geoPoint.longitude];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark* placemark = placemarks.firstObject;
        self.searchTextField.text = @"";
        UIColor *color = RED_LIGHT;
        self.searchTextField.attributedPlaceholder =
        [[NSAttributedString alloc]
         initWithString:[NSString stringWithFormat:@"الموقع الحالي: %@, %@", placemark.locality, placemark.administrativeArea]
         attributes:@{NSForegroundColorAttributeName:color}];

        self.searchTextField.textAlignment = NSTextAlignmentCenter;
    }];
    if ([self.curUser.useAddress isEqualToString:@"YES"]) {
        self.curUser.useAddress = @"NO";
        [self.curUser saveEventually:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [self currentLocationIdentifier];
            }
        }];
    }
}

@end

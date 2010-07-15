//
//  CitySelectionView.h
//  iSpeak
//
//  Created by Junqiang You on 5/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#define countryComponent 0
#define cityComponent 1

@interface CitySelectionView2 : UIView  <UIPickerViewDelegate, UIPickerViewDataSource>{
	NSArray *countryList;
	NSArray *cityList;
	NSDictionary *countryCityLookup;
	NSString *selectedCity;
	NSString *selectedCountry;
	
	UIPickerView *picker;
	UIButton *doneButton;
	
}

@property(nonatomic, retain) UIPickerView *picker;
@property(nonatomic, retain) UIButton *doneButton;
@property(nonatomic, retain) NSString *selectedCity;
@property(nonatomic, retain) NSString *selectedCountry;
@property(nonatomic, retain) NSArray *countryList;
@property(nonatomic, retain) NSArray *cityList;
@property(nonatomic, retain) NSDictionary *countryCityLookup;
//- (NSString *)selectedCity;
//- (NSString *)selectedState;
//- (NSString *)selectedCountry;
-(id)initWithFrame:(CGRect)frame country:(NSString*)country city:(NSString*)city;
-(void)setPickerSelections;
-(void)populdateDataWithSelectedCountry:(NSString*)country city:(NSString*)city;
@end

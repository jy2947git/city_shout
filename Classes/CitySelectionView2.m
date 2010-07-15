//
//  CitySelectionView.m
//  iSpeak
//
//  Created by Junqiang You on 5/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CitySelectionView2.h"


@implementation CitySelectionView2
@synthesize countryList;
@synthesize cityList;
@synthesize countryCityLookup;
@synthesize selectedCountry;
@synthesize selectedCity;
@synthesize picker;
@synthesize doneButton;

-(id)initWithFrame:(CGRect)frame country:(NSString*)country city:(NSString*)city{
	if((self = [super initWithFrame:frame])){
		self.backgroundColor=[UIColor blueColor];
		//create the picker and done button
		UIPickerView *p = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
		self.picker=p;
		[p release];
		UIButton *b=[UIButton buttonWithType:UIButtonTypeRoundedRect];
		b.frame=CGRectMake(130, 225, 80, 30) ;
		[b setTitle:@"Done" forState:UIControlStateNormal];
		self.doneButton=b;
		//
		[self populdateDataWithSelectedCountry:country city:city];
		self.picker.showsSelectionIndicator=YES;
		self.picker.dataSource=self;
		self.picker.delegate=self;
		[self setPickerSelections];
		
		[self addSubview:self.picker];
		[self addSubview:self.doneButton];
	}
	
	return self;
	
}

-(void)populdateDataWithSelectedCountry:(NSString*)country city:(NSString*)city{
	//load the country-state-city lookup
	NSBundle *mainBundle = [NSBundle mainBundle];
	NSString *csdictionaryPath = [mainBundle pathForResource:@"countryCityLookup" ofType:@"plist"];
	NSDictionary *csd = [[NSDictionary alloc] initWithContentsOfFile:csdictionaryPath];
	self.countryCityLookup = csd;
	[csd release];
	//set up picker components
	NSArray *countries = [self.countryCityLookup allKeys];
	NSArray *sortedCountries = [countries sortedArrayUsingSelector:@selector(compare:)];
	self.countryList = sortedCountries;
	self.selectedCountry=country;
	if(self.selectedCountry==nil){
		self.selectedCountry=[self.countryList objectAtIndex:0];
	}
	
	NSArray *selectedCountryCities = [self.countryCityLookup objectForKey:self.selectedCountry];
	NSArray *sortedCities = [selectedCountryCities sortedArrayUsingSelector:@selector(compare:)];
	self.cityList=sortedCities;

	self.selectedCity=city;
	if(self.selectedCity==nil){
		self.selectedCity=[cityList objectAtIndex:0];
	}
}

-(void)setPickerSelections{
	[self.picker selectRow:[self.countryList indexOfObject:self.selectedCountry] inComponent:countryComponent animated:YES];
	[self.picker selectRow:[self.cityList indexOfObject:self.selectedCity] inComponent:cityComponent animated:YES];
}



- (void)drawRect:(CGRect)rect {
    // Drawing code
	
}


- (void)dealloc {
	[doneButton release];
	[picker release];
	[selectedCountry release];
	[selectedCity release];
	[countryList release];
	[cityList release];
	[countryCityLookup release];
    [super dealloc];
}

- (CGFloat)pickerView:(UIPickerView *)pickerViewrowHeightForComponent:(NSInteger)component{
	return 14;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
	return 2;
}
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component{
	if(component==countryComponent){
		return 120;
	}else if(component==cityComponent){
		return 300;
	}
	return 120;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
	if(component==countryComponent){
		return [self.countryList count];
	}else if(component==cityComponent){
		return [self.cityList count];
	}
	return 1;
	
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
	if(component==countryComponent){
		return [self.countryList objectAtIndex:row];
	}else if(component==cityComponent){
		return [self.cityList objectAtIndex:row];
	}
	return @"";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
	if(component==countryComponent){
		//reload state
		NSString *s = [self.countryList objectAtIndex:row];
		NSArray *a = [self.countryCityLookup objectForKey:s];
		NSArray *sortedCities = [a sortedArrayUsingSelector:@selector(compare:)];
		self.cityList=sortedCities;
		//set default city
		[self.picker selectRow:0 inComponent:cityComponent animated:YES];
		[self.picker reloadComponent:cityComponent];
		
		self.selectedCountry = [self.countryList objectAtIndex:[self.picker selectedRowInComponent:countryComponent]];
		self.selectedCity = [self.cityList objectAtIndex:[self.picker selectedRowInComponent:cityComponent]];
	}else if(component==cityComponent){
		self.selectedCity = [self.cityList objectAtIndex:[self.picker selectedRowInComponent:cityComponent]];
	}
}


@end

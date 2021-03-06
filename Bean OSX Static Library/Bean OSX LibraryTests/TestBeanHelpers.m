#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "PTDBean.h"
#import "PTDFirmwareHelper.h"
#import "StatelessUtils.h"

@interface TestBeanHelpers : XCTestCase

@end

@implementation TestBeanHelpers

/**
 *  Ensure that firmwareUpdateRequiredForBean returns proper values for different firmwares and Beans.
 */
- (void)testfirmwareUpdateRequiredForBean
{
    NSString *oldDate = @"199201110734 Img-X";
    NSString *nowDate = @"201602290130 Img-A";
    NSString *futureDate = @"206304050000 Img-B";
    NSString *oadFirmware = @"OAD Img B";
    
    NSString *oldDateFirmware = @"199201110734";
    NSString *nowDateFirmware = @"201602290130";
    NSString *futureDateFirmware = @"206304050000";
    
    PTDBean *oldBean = [StatelessUtils fakeBeanWithFirmware:oldDate];
    PTDBean *nowBean = [StatelessUtils fakeBeanWithFirmware:nowDate];
    PTDBean *futureBean = [StatelessUtils fakeBeanWithFirmware:futureDate];
    PTDBean *oadBean = [StatelessUtils fakeBeanWithFirmware:oadFirmware];
    
    // Verify our mock works properly
    XCTAssertTrue([oldBean.firmwareVersion isEqualToString:oldDate]);
    
    NSError *error;
    
    // Success cases

    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:oldBean availableFirmware:oldDateFirmware withError:&error], FirmwareStatusUpToDate);
    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:oldBean availableFirmware:nowDateFirmware withError:&error], FirmwareStatusBeanNeedsUpdate);
    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:oldBean availableFirmware:futureDateFirmware withError:&error], FirmwareStatusBeanNeedsUpdate);
    
    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:nowBean availableFirmware:oldDateFirmware withError:&error], FirmwareStatusBeanIsNewerThanAvailable);
    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:nowBean availableFirmware:nowDateFirmware withError:&error], FirmwareStatusUpToDate);
    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:nowBean availableFirmware:futureDateFirmware withError:&error], FirmwareStatusBeanNeedsUpdate);
    
    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:futureBean availableFirmware:oldDateFirmware withError:&error], FirmwareStatusBeanIsNewerThanAvailable);
    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:futureBean availableFirmware:nowDateFirmware withError:&error], FirmwareStatusBeanIsNewerThanAvailable);
    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:futureBean availableFirmware:futureDateFirmware withError:&error], FirmwareStatusUpToDate);
    
    // Ensure OAD beans always get an update
    XCTAssertTrue([PTDFirmwareHelper firmwareUpdateRequiredForBean:oadBean availableFirmware:oldDateFirmware withError:&error]);
    XCTAssertTrue([PTDFirmwareHelper firmwareUpdateRequiredForBean:oadBean availableFirmware:nowDateFirmware withError:&error]);
    XCTAssertTrue([PTDFirmwareHelper firmwareUpdateRequiredForBean:oadBean availableFirmware:futureDateFirmware withError:&error]);

    // Ensure no method above errored out
    XCTAssertNil(error);

    // Failure cases

    PTDBean *beanWithInvalidDate = OCMClassMock([PTDBean class]);
    OCMStub(beanWithInvalidDate.firmwareVersion).andReturn(@"NOT_A_NUMBER");

    // Should fail when Bean has an invalid date
    error = nil;
    XCTAssertFalse([PTDFirmwareHelper firmwareUpdateRequiredForBean:beanWithInvalidDate availableFirmware:futureDateFirmware withError:&error]);
    XCTAssertNotNil(error);
}

/**
 *  Ensure the OAD image recognition picks out Beans running OAD images and misses edge cases.
 */
- (void)testOadImageRunningOnBean
{
    // When OAD is at the start
    XCTAssertTrue([PTDFirmwareHelper oadImageRunningOnBean:[StatelessUtils fakeBeanWithFirmware:@"OAD Img A"]]);
    XCTAssertTrue([PTDFirmwareHelper oadImageRunningOnBean:[StatelessUtils fakeBeanWithFirmware:@"OAD XYZ"]]);

    // When OAD is in the middle or at the end
    XCTAssertTrue([PTDFirmwareHelper oadImageRunningOnBean:[StatelessUtils fakeBeanWithFirmware:@"Test OAD Image"]]);
    XCTAssertTrue([PTDFirmwareHelper oadImageRunningOnBean:[StatelessUtils fakeBeanWithFirmware:@"Another OAD"]]);

    // When OAD is touching word boundaries
    XCTAssertTrue([PTDFirmwareHelper oadImageRunningOnBean:[StatelessUtils fakeBeanWithFirmware:@"OAD-Force-One"]]);
    XCTAssertTrue([PTDFirmwareHelper oadImageRunningOnBean:[StatelessUtils fakeBeanWithFirmware:@"   OAD   "]]);
    // Underscores will mess it up
    XCTAssertFalse([PTDFirmwareHelper oadImageRunningOnBean:[StatelessUtils fakeBeanWithFirmware:@"YES_OAD"]]);

    // Not when OAD is part of another word
    XCTAssertFalse([PTDFirmwareHelper oadImageRunningOnBean:[StatelessUtils fakeBeanWithFirmware:@"RAINBOW ROAD"]]);
    XCTAssertFalse([PTDFirmwareHelper oadImageRunningOnBean:[StatelessUtils fakeBeanWithFirmware:@"ROADIE"]]);

    // Not when OAD is lowercase
    XCTAssertFalse([PTDFirmwareHelper oadImageRunningOnBean:[StatelessUtils fakeBeanWithFirmware:@"Frog and Toad"]]);
    XCTAssertFalse([PTDFirmwareHelper oadImageRunningOnBean:[StatelessUtils fakeBeanWithFirmware:@"super oad jr"]]);
    XCTAssertFalse([PTDFirmwareHelper oadImageRunningOnBean:[StatelessUtils fakeBeanWithFirmware:@"oad image a"]]);
}

@end

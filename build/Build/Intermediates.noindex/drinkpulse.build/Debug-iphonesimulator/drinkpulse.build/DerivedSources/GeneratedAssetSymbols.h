#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.haniewicz.drinkpulse";

/// The "RiskHigh" asset catalog color resource.
static NSString * const ACColorNameRiskHigh AC_SWIFT_PRIVATE = @"RiskHigh";

/// The "RiskLow" asset catalog color resource.
static NSString * const ACColorNameRiskLow AC_SWIFT_PRIVATE = @"RiskLow";

/// The "RiskModerate" asset catalog color resource.
static NSString * const ACColorNameRiskModerate AC_SWIFT_PRIVATE = @"RiskModerate";

#undef AC_SWIFT_PRIVATE

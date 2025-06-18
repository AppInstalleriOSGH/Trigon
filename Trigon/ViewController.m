// ViewController.m
// Trigon, 2025

#import "ViewController.h"
#import "Exploit/info.h"

uint64_t trigon(void);

@interface ViewController ()
@end

@implementation ViewController

- (void)loadView {
    [super loadView];
    
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    UIButton *centerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [centerButton setTitle:@"Press Me" forState:UIControlStateNormal];
    centerButton.frame = CGRectMake(0, 0, 150, 50); // Width: 150, Height: 50

    // Center the button in its superview (assuming self.view is available)
    centerButton.center = self.view.center;

    // Optional: Add target/action
    [centerButton addTarget:self action:@selector(run:) forControlEvents:UIControlEventTouchUpInside];

    // Add the button to the view
    [self.view addSubview:centerButton];

}

-(void)run:(UIButton *)sender {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 350, 150)];
    //label.center = self.view.center;
    label.center = CGPointMake(self.view.center.x, self.view.center.y + 50);
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    label.numberOfLines = 3;
    
    uint64_t result = trigon();
    label.text = !result ? [NSString stringWithFormat:@"Exploit success!\nUID: %u, Escaped Sandbox: %@\nKernel Phys Base: 0x%llX", getuid(), [[NSFileManager defaultManager] isReadableFileAtPath:@"/var"] ? @"YES" : @"NO", gDeviceInfo.kernelPhysBase] : [NSString stringWithFormat:@"Exploit failed.\nResult: 0x%llX.", result];
    [self.view addSubview:label];
}

@end

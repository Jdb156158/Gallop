
/********************* 有任何问题欢迎反馈给我 liuweiself@126.com ****************************************/
/***************  https://github.com/waynezxcv/Gallop 持续更新 ***************************/
/******************** 正在不断完善中，谢谢~  Enjoy ******************************************************/




#import "HTMLParsingViewController.h"
#import "LWAlertView.h"
#import "Gallop.h"
#import "WebViewController.h"
#import "LWLoadingView.h"


@interface HTMLParsingViewController ()<LWHTMLDisplayViewDelegate>

@property (nonatomic,strong) LWHTMLDisplayView* htmlView;
@property (nonatomic,assign) BOOL isNeedRefresh;

@end

@implementation HTMLParsingViewController

#pragma mark - ViewControllerLifeCycle

- (void)loadView {
    [super loadView];
    self.isNeedRefresh = YES;
    self.title = @"HTML Parsing";
    self.view.backgroundColor = [UIColor whiteColor];
    self.htmlView = [[LWHTMLDisplayView alloc] initWithFrame:self.view.bounds];
    self.htmlView.displayDelegate = self;
    [self.view addSubview:self.htmlView];

    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 80.0f, 30.0f);
    [button setTitle:@"UIWebView" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    button.titleLabel.textAlignment = NSTextAlignmentRight;
    [button addTarget:self action:@selector(UIWebView) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}

- (void)UIWebView {
    WebViewController* vc = [[WebViewController alloc] init];
    vc.URL = self.URL;
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)lwhtmlDisplayView:(LWHTMLDisplayView *)asyncDisplayView didCilickedTextStorage:(LWTextStorage *)textStorage linkdata:(id)data {
    [LWAlertView shoWithMessage:data];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.isNeedRefresh) {
        self.isNeedRefresh = NO;
        [self _pasering];
    }
}

- (void)_pasering {
    [LWLoadingView showInView:self.view];
    __weak typeof(self) weakSelf = self;
    [self downloadDataCompletion:^(NSData *data) {
        LWLayout* layout = [[LWLayout alloc] init];
        LWStorageBuilder* builder = [[LWStorageBuilder alloc] initWithData:data encoding:NSUTF8StringEncoding];
        /** cover  **/
        LWHTMLImageConfig* coverConfig = [[LWHTMLImageConfig alloc] init];
        coverConfig.size = CGSizeMake(SCREEN_WIDTH, 300.0f);
        [builder createLWStorageWithXPath:@"//div[@class='img-wrap']/img"
                               edgeInsets:UIEdgeInsetsMake(-10, 0, 0, 0)
                         configDictionary:@{@"img":coverConfig}];
        [layout addStorages:builder.storages];//封面

        /** title  **/
        LWHTMLTextConfig* titleConfig = [[LWHTMLTextConfig alloc] init];
        titleConfig.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:18.0];
        titleConfig.textColor = [UIColor blackColor];
        [builder createLWStorageWithXPath:@"//div[@class='img-wrap']/h1"
                               edgeInsets:UIEdgeInsetsMake([layout suggestHeightWithBottomMargin:10.0f], 10.0f, 10.0, 10.0f)
                         configDictionary:@{@"h1":titleConfig}];
        [layout addStorages:builder.storages];//标题

        /** avatar  **/
        CGFloat avatarTop = [layout suggestHeightWithBottomMargin:10.0f];
        LWHTMLImageConfig* avatarConfig = [[LWHTMLImageConfig alloc] init];
        avatarConfig.size = CGSizeMake(40.0f, 40.0f);
        [builder createLWStorageWithXPath:@"//div[@class='meta']/img"
                               edgeInsets:UIEdgeInsetsMake(avatarTop, 10.0f, 10.0,10.0f)
                         configDictionary:@{@"img":avatarConfig}];
        [layout addStorages:builder.storages];//头像

        /** name  **/
        LWHTMLTextConfig* nameConfig = [[LWHTMLTextConfig alloc] init];
        nameConfig.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:15.0f];
        nameConfig.textColor = [UIColor blackColor];
        [builder createLWStorageWithXPath:@"//div[@class='meta']/span[@class='author']"
                               edgeInsets:UIEdgeInsetsMake(avatarTop, 60.0f, 10.0, 10.0f)
                         configDictionary:@{@"span":nameConfig}];
        LWTextStorage* nameStorage = (LWTextStorage*)builder.firstStorage;

        /** description  **/
        LWHTMLTextConfig* desConfig = [[LWHTMLTextConfig alloc] init];
        desConfig.font = [UIFont fontWithName:@"Heiti SC" size:15.0f];
        desConfig.textColor = [UIColor grayColor];
        [builder createLWStorageWithXPath:@"//div[@class='meta']/span[@class='bio']"
                               edgeInsets:UIEdgeInsetsMake(avatarTop,60.0f, 10.0, 10.0f)
                         configDictionary:@{@"span":desConfig}];
        LWTextStorage* desStorage =(LWTextStorage*)builder.firstStorage;
        [nameStorage lw_appendTextStorage:desStorage];
        [layout addStorage:nameStorage];

        /** content  **/
        LWHTMLTextConfig* contentConfig = [[LWHTMLTextConfig alloc] init];
        contentConfig.font = [UIFont fontWithName:@"Heiti SC" size:15.0f];
        contentConfig.textColor = RGB(50, 50, 50, 1);
        contentConfig.linkColor = RGB(232, 104, 96,1.0f);
        contentConfig.linkHighlightColor = RGB(0, 0, 0, 0.35f);
        [builder createLWStorageWithXPath:@"//div[@class='content']/p"
                               edgeInsets:UIEdgeInsetsMake([layout suggestHeightWithBottomMargin:10.0f], 10.0f, 10.0, 10.0f)
                         configDictionary:@{@"p":contentConfig}];
        [layout addStorages:builder.storages];//正文
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.htmlView.layout = layout;
            [LWLoadingView hideInViwe:weakSelf.view];
        });
    }];
}

- (void)downloadDataCompletion:(void(^)(NSData* data))completion {
    NSURLSession* session = [NSURLSession sessionWithConfiguration:
                             [NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:self.URL];
    NSURLSessionDataTask* task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData * _Nullable data,
                                   NSURLResponse * _Nullable response,
                                   NSError * _Nullable error) {
                   completion(data);
               }];
    [task resume];
}


@end

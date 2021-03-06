//
//  TimeLineTableViewController.m
//  Infinity
//
//  Created by 大澤卓也 on 2014/06/14.
//  Copyright (c) 2014年 ___FULLUSERNAME__. All rights reserved.
//

#import "TimeLineTableViewController.h"

@interface TimeLineTableViewController ()
@property (nonatomic) dispatch_queue_t mainQueue;
@property (nonatomic )dispatch_queue_t imageQueue;
@property (nonatomic,copy)NSString *httpErrorMessage;
@property (nonatomic,copy)NSArray *timeLineData;

@end

@implementation TimeLineTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (IBAction)postTweet:(id)sender {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        NSString *serviceType= SLServiceTypeTwitter;
        SLComposeViewController *composeCtl=
        [SLComposeViewController composeViewControllerForServiceType:serviceType];
        [composeCtl setCompletionHandler:^(SLComposeViewControllerResult result){
            if (result == SLComposeViewControllerResultDone) {
                
                
            }
        }];
        [self presentViewController:composeCtl animated: YES completion:nil];
        
    }

}

-(void)timeLineView{
    [_postview setDelegate:self];
    [_postview setDataSource:self];
    
    UIRefreshControl * refreshControl = [[UIRefreshControl alloc]init];
    [refreshControl addTarget:self action:@selector(pullDown:) forControlEvents:UIControlEventValueChanged];
    [_postview addSubview:refreshControl];
    [_postview reloadData];
    self.mainQueue =dispatch_get_main_queue();
    self.imageQueue =dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    [_postview registerClass:[TimeLineCell class] forCellReuseIdentifier:@"TimeLineCell"];
    ACAccountStore *accountStore =[[ACAccountStore alloc]init];
    ACAccount *account =[accountStore accountWithIdentifier:self.identifier];
    NSLog(@"account = %@", self.identifier) ;
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    NSDictionary *params= @{@"count":@"50",
                            @"trim_user":@"0",
                            @"include_entities":@"0"};
    SLRequest *request =[SLRequest requestForServiceType: SLServiceTypeTwitter
                                           requestMethod:SLRequestMethodGET
                                                     URL:url
                                              parameters:params];
    request.account =account;
    
    UIApplication *application =[UIApplication sharedApplication];
    application.networkActivityIndicatorVisible=YES;
    
    [request performRequestWithHandler:^(NSData *responseDate,
                                         NSHTTPURLResponse *urlResponse,
                                         NSError *error){
        if(responseDate){
            self.httpErrorMessage =nil;
            if(urlResponse.statusCode >=200 && urlResponse.statusCode<300){
                NSError *jsonError;
                self.timeLineData =
                [NSJSONSerialization JSONObjectWithData:responseDate
                                                options:NSJSONReadingAllowFragments
                                                  error:&jsonError];
                if (self.timeLineData) {
                    NSLog(@"TimeLine Response:%@\n",self.timeLineData);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadData];
                    });
                }else{
                    NSLog(@"JSON Error: %@",[jsonError localizedDescription]);
                }
            }else{
                self.httpErrorMessage=
                [NSString stringWithFormat:@"The response status code is %ld",
                 (long)urlResponse.statusCode];
                NSLog(@"HTTP Error:%@",self.httpErrorMessage);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_postview reloadData];
                });
            }
        }else{
            NSLog(@"ERROR:An error occurred while requesting:%@",[error localizedDescription]);
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            UIApplication *application =[UIApplication sharedApplication];
            application.networkActivityIndicatorVisible =NO;
            if (self.refreshControl.refreshing) {
                [self.refreshControl endRefreshing];
            }
        });
    }];

}
- (void)viewDidLoad
{

    [super viewDidLoad];
    [self timeLineView];
    }

    -(NSAttributedString *)labelAttributedString:(NSString *)labelString
    {
        NSString *text=(labelString ==nil)? @"":labelString;
        
        UIFont *font =[UIFont fontWithName:@"HiraKakuProN-W3" size:13];
        CGFloat customLineHeight =19.5f;
        
        NSMutableParagraphStyle *paragraphStyle =[[NSMutableParagraphStyle alloc]init];
        paragraphStyle.minimumLineHeight =customLineHeight;
        paragraphStyle.maximumLineHeight =customLineHeight;
        
        NSDictionary *attributes= @{NSParagraphStyleAttributeName:paragraphStyle,
                                    NSFontAttributeName:font};
        NSMutableAttributedString *attributedText=
        [[NSMutableAttributedString alloc]initWithString:text attributes: attributes];
        
        return attributedText;
        // Uncomment the following line to preserve selection between presentations.
        // self.clearsSelectionOnViewWillAppear = NO;
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
-(CGFloat)labelHeight:(NSAttributedString *)attributedText
{
    CGFloat aHeight =[attributedText boundingRectWithSize:CGSizeMake(257, MAXFLOAT)
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                                  context:nil].size.height;
    return aHeight;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)refreshAction:(id)sender
{
    [self.refreshControl beginRefreshing];
    

}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in the section.
    if (!self.timeLineData) {
        return 1;
    }else{
        
    
    return [self.timeLineData count];
}
}

 - (UITableViewCell *)tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath

 {
 TimeLineCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimeLineCell" forIndexPath:indexPath];
 // Configure the cell...
     if(self.httpErrorMessage) {
         cell.tweetTextLabel.text = @"HTTP ErrorMessage";
         cell.tweetTextLabelHeight = 24.0;
     } else if (!self.timeLineData) {
         cell.tweetTextLabel.text = @"Loading...";
         cell.tweetTextLabelHeight = 24.0;
     } else {
         NSString *tweetText = self.timeLineData[indexPath.row][@"text"];
         NSAttributedString *attributedTweetText = [self labelAttributedString:tweetText];
         
         cell.tweetTextLabel.attributedText = attributedTweetText;
         cell.nameLabel.text = self.timeLineData[indexPath.row][@"user"][@"screen_name"];
         cell.profileImageView.image = [UIImage imageNamed:@"blank.png"];
         cell.tweetTextLabelHeight = [self labelHeight:attributedTweetText];
         
         UIApplication *application = [UIApplication sharedApplication];
         application.networkActivityIndicatorVisible = YES;
         
         dispatch_async(self.imageQueue, ^{
             NSString *url;
             NSDictionary *tweetDictionary = self.timeLineData[indexPath.row];
             
             if ([[tweetDictionary allKeys] containsObject:@"retweeted_status"]) {
                 // リツイートの場合はretweeted_statusキー項目が存在する
                 url = tweetDictionary[@"retweeted_status"][@"user"][@"profile_image_url"];
             } else {
                 url = tweetDictionary[@"user"][@"profile_image_url"];
             }
             
             NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
             dispatch_async(self.mainQueue, ^{
                 UIApplication *application = [UIApplication sharedApplication];
                 application.networkActivityIndicatorVisible = NO;
                 UIImage *image = [[UIImage alloc] initWithData:data];
                 cell.profileImageView.image = image;
                 [cell setNeedsLayout];
             });
         });
     }
 return cell;
 }
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //SharedDataManager *sharedManager = [SharedDataManager sharedManager];
    
    NSString *tweetText = self.timeLineData[indexPath.row][@"text"];
    NSAttributedString *attributedTweetText = [self labelAttributedString:tweetText];
    CGFloat tweetTextLabelHeight = [self labelHeight:attributedTweetText];
    CGRect r1 = [[UIScreen mainScreen] bounds];

    return  tweetTextLabelHeight +35 * (r1.size.height/568);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TimeLineCell *cell = (TimeLineCell *)[tableView cellForRowAtIndexPath:indexPath];
    DetailViewController *detailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"DetailViewController"];
    detailViewController.name = cell.nameLabel.text;
    detailViewController.text = cell.tweetTextLabel.text;
    detailViewController.image = cell.profileImageView.image;
    detailViewController.identifier = self.identifier;
    detailViewController.idStr = self.timeLineData[indexPath.row][@"id_str"];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

- (void)pullDown:(id)sender
{
    // 更新開始
   
    [sender beginRefreshing];
    [self.tableView beginUpdates];
    NSLog(@"更新");
    // 更新終了
    dispatch_async(dispatch_get_main_queue(), ^{
        [self timeLineView];
            });
    
    [self.tableView endUpdates];
    [sender endRefreshing];
    [self.tableView reloadData];
    }
/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
@end

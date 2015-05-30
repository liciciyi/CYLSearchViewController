//
//  CYLSearchController.m
//  http://cnblogs.com/http://weibo.com/luohanchenyilong//
//
//  Created by https://github.com/http://weibo.com/luohanchenyilong/ on 14-5-20.
//  Copyright (c) 2014年 com.http://cnblogs.com/http://weibo.com/luohanchenyilong//. All rights reserved.
//
#import <Foundation/Foundation.h>

#define kAppColor  [UIColor colorWithRed:0/255.f green:150/255.f blue:136/255.f alpha:0.8f]
#define kAppWordColor  [UIColor colorWithRed:0/255.f green:150/255.f blue:136/255.f alpha:0.8f]
#define BACKGROUND_COLOR [UIColor colorWithRed:229/255.f green:238/255.f blue:235/255.f alpha:1.f] // 浅绿色背景
#define TABLE_LINE_COLOR [UIColor colorWithRed:200/255.f green:199/255.f blue:204/255.f alpha:1.f].CGColor // 列表分割线颜色

static NSString *const kSearchHistory = @"kSearchHistory";
static float const kHeightForFooterInSection = 64;

enum {
    kMostNumberOfSearchHistories = 15
};

#import "CYLSearchController.h"
//#import "Constant.h"
#import <QuartzCore/QuartzCore.h>
#import "Util.h"
#import "AppDelegate.h"
#import "CYLSearchResultViewController.h"
#import "CYLSearchBar.h"

@interface CYLSearchController ()
<
UITextFieldDelegate,
UITableViewDelegate,
UITableViewDataSource,
UISearchBarDelegate
>

{
    BOOL _showQuestions; // 判断列表的显示内容是搜索记录，还是问题
    UIViewController *_inController; // 此界面被显示在哪个View Controller
}

@property (nonatomic, strong) NSMutableArray *searchHistories;
@property (nonatomic, strong) NSMutableArray *questionDataSource;
@property (nonatomic, strong) UILabel *titleLbl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) CYLSearchBar *searchBar;
@property (nonatomic, strong) UIView *searchBgView;

@end

@implementation CYLSearchController

#pragma mark - 💤 LazyLoad Method

/**
 *  懒加载_searchBgVie
 w
 *
 *  @return UIView
 */
- (UIView *)searchBgView
{
    if (_searchBgView == nil) {
        _searchBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        //仅修改_searchBgView的y,xwh值不变
        _searchBgView.frame = CGRectMake(_searchBgView.frame.origin.x, 44, _searchBgView.frame.size.width, _searchBgView.frame.size.height);
        _searchBgView.backgroundColor = [UIColor blackColor];
        _searchBgView.alpha = 0;
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide:)];
        [_searchBgView addGestureRecognizer:recognizer];
    }
    return _searchBgView;
}

/**
 *  懒加载_titleLbl
 *
 *  @return UILabel
 */
- (UILabel *)titleLbl
{
    if (_titleLbl == nil) {
        _titleLbl = [[UILabel alloc] init];
        _titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(12, 14, 200, 16)];
        _titleLbl.textColor = kAppWordColor;
        _titleLbl.font = [UIFont systemFontOfSize:14];
    }
    return _titleLbl;
}

/**
 *  懒加载_searchBar
 *
 *  @return UISearchBar
 */
- (CYLSearchBar *)searchBar
{
    if (_searchBar == nil) {
        _searchBar = [[CYLSearchBar alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
        // 删除UISearchBar中的UISearchBarBackground
        [_searchBar setShowsCancelButton:YES animated:YES];
        _searchBar.delegate = self;
    }
    return _searchBar;
}

/**
 *  懒加载_questionDataSource
 *
 *  @return NSMutableArray
 */
- (NSMutableArray *)questionDataSource
{
    if (_questionDataSource == nil) {
        _questionDataSource = [[NSMutableArray alloc] init];
    }
    return _questionDataSource;
}

#pragma mark - ♻️ LifeCycle Method

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSLog(@"initWithNibName:bundle%@", self.view);
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        //仅修改self.tableView的高度,xyw值不变
        self.tableView.frame = CGRectMake(self.tableView.frame.origin.x,
                                          self.tableView.frame.origin.y,
                                          self.tableView.frame.size.width,
                                          0);
        self.searchHistories = [NSMutableArray array];
        _showQuestions = NO;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage
                                                                 imageWithColor:TEXTFIELD_BACKGROUNDC0LOR]
                                                  forBarMetrics:UIBarMetricsDefault];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage
                                                                 imageWithColor:APP_TINT_COLOR
                                                                 ]
                                                  forBarMetrics:UIBarMetricsDefault];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"返回";
    self.navigationItem.titleView = self.searchBar;
    [self.navigationController.navigationBar setNeedsLayout];
    //仅修改self.navigationController.view的高度,xyw值不变
    self.navigationController.view.frame = CGRectMake(self.navigationController.view.frame.origin.x,
                                                      self.navigationController.view.frame.origin.y,
                                                      self.navigationController.view.frame.size.width,
                                                      44);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self hide:nil];
}

#pragma mark - 🆑 CYL Custom Method

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}
/**
 *  显示搜索界面
 */
- (void)showInViewController:(UIViewController *)controller
{
    AppDelegate *delegate = ((AppDelegate *)[[UIApplication sharedApplication] delegate]);
    [delegate.navigationController.view addSubview:self.searchBgView];
    [delegate.navigationController.view addSubview:self.navigationController.view];
    
    //仅修改self.navigationController.view的y,xwh值不变
    self.navigationController.view.frame = CGRectMake(self.navigationController.view.frame.origin.x,
                                                      44,
                                                      self.navigationController.view.frame.size.width,
                                                      self.navigationController.view.frame.size.height
                                                      );
    [delegate.navigationController setNavigationBarHidden:YES animated:YES];
    [UIView animateWithDuration:0.25f animations:^{
        //仅修改self.navigationController.view的y,xwh值不变
        self.navigationController.view.frame = CGRectMake(self.navigationController.view.frame.origin.x,
                                                          0,
                                                          self.navigationController.view.frame.size.width,
                                                          self.navigationController.view.frame.size.height
                                                          );
        self.searchBgView.alpha = 0.4f;
    } completion:^(BOOL finished) {
        NSArray *histories = [[NSUserDefaults standardUserDefaults] objectForKey:kSearchHistory];
        [_searchHistories addObjectsFromArray:histories];
        [self reloadViewLayouts];
        [self.tableView reloadData];
        [self.searchBar becomeFirstResponder];
    }];
}

/**
 *  关闭搜索界面
 *
 *  @param completion 操作执行完成后执行
 */
- (void)hide:(void(^)(void))completion
{
    AppDelegate *delegate = ((AppDelegate *)[[UIApplication sharedApplication] delegate]);
    [delegate.navigationController setNavigationBarHidden:NO animated:YES];
    [UIView animateWithDuration:0.25f animations:^{
        //仅修改self.navigationController.view的y,xwh值不变
        self.navigationController.view.frame = CGRectMake(self.navigationController.view.frame.origin.x,
                                                          44,
                                                          self.navigationController.view.frame.size.width,
                                                          self.navigationController.view.frame.size.height
                                                          );
        self.searchBgView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.searchBgView removeFromSuperview];
        self.searchBgView = nil;
        [UIView animateWithDuration:0.2f animations:^{
            self.navigationController.view.alpha = 0;
        } completion:^(BOOL finished) {
            [self.navigationController.view removeFromSuperview];
        }];
    }];
    completion ? completion() : nil;
}

/**
 *  刷新界面控件
 */
- (void)reloadViewLayouts
{
    if (_showQuestions) {
        // 用户点击搜索，搜索出问题时，显示问题列表
        //仅修改self.view的高度,xyw值不变
        self.view.frame = CGRectMake(self.view.frame.origin.x,
                                     self.view.frame.origin.y,
                                     self.view.frame.size.width,
                                     [UIScreen mainScreen].bounds.size.height - 64
                                     );
        //仅修改self.tableView的高度,xyw值不变
        self.tableView.frame = CGRectMake(self.tableView.frame.origin.x,
                                          self.tableView.frame.origin.y,
                                          self.tableView.frame.size.width,
                                          self.view.frame.size.height
                                          );
        //仅修改self.navigationController.view的高度,xyw值不变
        self.navigationController.view.frame = CGRectMake(self.navigationController.view.frame.origin.x,
                                                          self.navigationController.view.frame.origin.y,
                                                          self.navigationController.view.frame.size.width,
                                                          [UIScreen mainScreen].bounds.size.height);
        
    } else {
        // 显示搜索记录
        //仅修改self.tableView的高度,xyw值不变
        self.tableView.frame = CGRectMake(self.tableView.frame.origin.x,
                                          self.tableView.frame.origin.y,
                                          self.tableView.frame.size.width,
                                          MIN(_searchHistories.count * 44 + (_searchHistories.count > 0 ? kHeightForFooterInSection : 0), [UIScreen mainScreen].bounds.size.height - 64));
        if (_searchHistories.count == 0) {
            // 没有搜索记录
            //仅修改self.view的高度,xyw值不变
            self.view.frame = CGRectMake(self.view.frame.origin.x,
                                         self.view.frame.origin.y,
                                         self.view.frame.size.width,
                                         CGRectGetMaxY(self.tableView.frame));
            //仅修改self.navigationController.view的高度,xyw值不变
            self.navigationController.view.frame = CGRectMake(self.navigationController.view.frame.origin.x,
                                                              self.navigationController.view.frame.origin.y,
                                                              self.navigationController.view.frame.size.width,
                                                              self.view.frame.size.height + 64);
        } else {
            // 有搜索记录
            //仅修改self.view的高度,xyw值不变
            self.view.frame = CGRectMake(self.view.frame.origin.x,
                                         self.view.frame.origin.y,
                                         self.view.frame.size.width,
                                         [UIScreen mainScreen].bounds.size.height - 64);
            //仅修改self.navigationController.view的高度,xyw值不变
            self.navigationController.view.frame = CGRectMake(self.navigationController.view.frame.origin.x,
                                                              self.navigationController.view.frame.origin.y,
                                                              self.navigationController.view.frame.size.width,
                                                              [UIScreen mainScreen].bounds.size.height);
        }
    }
}

/**
 *  清除搜索记录
 */
- (void)clearHistoriesButtonClicked:(id)sender
{
    [_searchHistories removeAllObjects];
    [[NSUserDefaults standardUserDefaults] setObject:_searchHistories forKey:kSearchHistory];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.tableView reloadData];
    [self reloadViewLayouts];
}

- (void)getQuestionList:(NSNumber *)startQid
{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    //构造元素需要使用两个空格来进行缩进，右括号]或者}写在新的一行，并且与调用语法糖那行代码的第一个非空字符对齐：
    NSArray *array = @[
                       @"测试1❤️",
                       @"测试2❤️",
                       @"测试3❤️",
                       @"测试4❤️"
                       ];
    self.questionDataSource = [NSMutableArray arrayWithArray:array];
    _showQuestions = YES;
    [self.tableView reloadData];
}

#pragma mark - 🔌 UITableViewDataSource Method

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_showQuestions) {
        self.navigationController.view.backgroundColor = BACKGROUND_COLOR;
        return self.questionDataSource.count;
    } else {
        self.navigationController.view.backgroundColor = [UIColor clearColor];
        return _searchHistories.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_showQuestions) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
            [cell.contentView addSubLayerWithFrame:CGRectMake(0,
                                                              44 - 0.5f,
                                                              [UIScreen mainScreen].bounds.size.width,
                                                              0.5f
                                                              )
                                             color:TABLE_LINE_COLOR];
            cell.textLabel.backgroundColor = [UIColor whiteColor];
        }
        cell.textLabel.text = self.questionDataSource[indexPath.row];
        cell.textLabel.font = [UIFont systemFontOfSize:14];        // 传入数据
        
        // 返回cell
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
            [cell.contentView addSubLayerWithFrame:CGRectMake(0,
                                                              44 - 0.5f,
                                                              [UIScreen mainScreen].bounds.size.width,
                                                              0.5f
                                                              )
                                             color:TABLE_LINE_COLOR];
            cell.textLabel.backgroundColor = [UIColor whiteColor];
        }
        cell.textLabel.text = _searchHistories[indexPath.row];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        return cell;
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_showQuestions) {
        return 44;
    } else {
        return 44;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(_showQuestions){
        return 44;
    }
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (!_showQuestions && _searchHistories.count > 0) {
        return kHeightForFooterInSection;
    }
    return 0.01;
}

#pragma mark - 🔌 UITableViewDelegatel Method

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (!_showQuestions && _searchHistories.count>0) {
        UIView *footerVw = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, kHeightForFooterInSection)];
        footerVw.backgroundColor = [UIColor whiteColor];
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width - 160)/2, 18, 160, 30)];
        [footerVw addSubview:btn];
        [btn setBackgroundColor:[UIColor whiteColor]];
        btn.layer.borderWidth = 0.5;
        btn.layer.borderColor =[UIColor lightGrayColor].CGColor;
        btn.layer.cornerRadius = 4;
        [btn setTitle:@"清除搜索历史" forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont fontWithName:@"Superclarendon-Light" size:16];
        [btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(clearHistoriesButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        return footerVw;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self reloadViewLayouts];
    if (_showQuestions) {
        // 点击问题，跳转到问题系那个情
        CYLSearchResultViewController *searchResultViewController =
        [[CYLSearchResultViewController alloc] initWithNibName:[[CYLSearchResultViewController class] description] bundle:nil];
        searchResultViewController.searchResult.titleLabel.text = self.questionDataSource[indexPath.row];
        [self.navigationController pushViewController:searchResultViewController animated:YES];
        [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        self.searchBar.text = _searchHistories[indexPath.row];
        [self getQuestionList:nil];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *header;
    if(_showQuestions)
    {
        header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
        header.backgroundColor = [UIColor whiteColor];
        [header addSubview:self.titleLbl];
        self.titleLbl.text = [NSString stringWithFormat:@"与%@有关的咨询", self.searchBar.text];
        
        UIView *cureLine = [[UIView alloc] initWithFrame:CGRectMake(12, 43.5, [UIScreen mainScreen].bounds.size.width - 12, 0.5)];
        cureLine.backgroundColor = [UIColor colorWithRed:224/255.f green:224/255.f blue:224/255.f alpha:1.f];
        [header addSubview:cureLine];
    }
    return header;
}

#pragma mark - 🔌 UISearchBarDelegate Method

/**
 *  点击输入框，显示搜索记录
 *
 */
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.searchBar.text = @"";
    if (_showQuestions) {
        _showQuestions = NO;
        //        self.tableView.infiniteScrollingView.enabled = NO;
        [self.tableView reloadData];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if (searchBar.text.length == 0) {
        return;
    }
    if ([_searchHistories containsObject:searchBar.text]) {
        [_searchHistories removeObject:searchBar.text];
    }
    // 保存搜索记录，最多10条
    [_searchHistories insertObject:searchBar.text atIndex:0];
    if (_searchHistories.count > kMostNumberOfSearchHistories) {
        [_searchHistories removeLastObject];
    }
    [[NSUserDefaults standardUserDefaults] setObject:_searchHistories forKey:kSearchHistory];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self reloadViewLayouts];
    [self.tableView reloadData];
    // 开始搜索
    [self getQuestionList:nil];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    if (_delegate && [_delegate respondsToSelector:@selector(questionSearchCancelButtonClicked:)]) {
        [_delegate questionSearchCancelButtonClicked:self];
    }
}

#pragma mark - 🔌 UIScrollViewDelegate Method

/**
 *  一旦滑动列表，隐藏键盘
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.searchBar.isFirstResponder) {
        [self.searchBar resignFirstResponder];
    }
}

@end



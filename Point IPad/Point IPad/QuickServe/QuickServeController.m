//
//  QuickServeController.m
//  Point IPad
//
//  Created by Developer on 4/22/13.
//  Copyright (c) 2013 Developer. All rights reserved.
//

#import "QuickServeController.h"
#import "QuickServeCell.h"
#import "ItemProperties.h"
#import "ItemColorProperties.h"
#import "QuickCollection.h"
#import "QuickCollectionFlow.h"
#import "QuickModifierController.h"
#import "QuickServeTableCell.h"
#import "QuickTable.h"
#import <QuartzCore/QuartzCore.h>
#import "PaymentTableViewController.h"
#import "PopUpModDescriptionViewController.h"
#import "HomeViewController.h"

@interface QuickServeController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
                                    UIActionSheetDelegate, UITableViewDataSource,
                                    UITableViewDelegate, QuickModifierControllerDelegate,
                                    UIAlertViewDelegate>

@property (retain, nonatomic) IBOutlet UITapGestureRecognizer *oneFingerOneTap;
@property (strong, nonatomic) QuickCollectionFlow *flowLayout;
@property (retain, nonatomic) IBOutlet UIToolbar *quickToolbar;
@property (strong, nonatomic) UIPopoverController *popover;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *modButton;


// Views
@property (retain, nonatomic) IBOutlet QuickCollection *quickCollectionView;
@property (retain, nonatomic) IBOutlet UIView *quickTopView;
@property (retain, nonatomic) IBOutlet QuickTable *quickTableView;

// Displays on quickTopView
@property (retain, nonatomic) IBOutlet UILabel *amountLabel;
@property (retain, nonatomic) IBOutlet UILabel *taxLabel;
@property (retain, nonatomic) IBOutlet UILabel *totalLabel;
@property (retain, nonatomic) IBOutlet UILabel *firstTaxLabel;
@property (retain, nonatomic) IBOutlet UILabel *secondTaxLabel;


@end

@implementation QuickServeController
@synthesize currentMenuItems;
@synthesize selectedItemIndex;
@synthesize isActualItems;
@synthesize isSubclass;
@synthesize flowLayout;
@synthesize quickCollectionView;
@synthesize oneFingerOneTap;
@synthesize stackOfMenus;
@synthesize stackOfIsActualItemBools;
@synthesize stackOfIsSubclassBools;
@synthesize order;
@synthesize nameOfSelected;
@synthesize classNameForDatabase;
@synthesize subclassNameForDatabase;
@synthesize selectedItemId;
@synthesize quickToolbar;
@synthesize modButton;
@synthesize popover;
@synthesize quickTableView;
@synthesize tableNumber;
@synthesize taxNameChanged;

@synthesize amountLabel;
@synthesize taxLabel;
@synthesize totalLabel;
@synthesize firstTaxLabel;
@synthesize secondTaxLabel;
@synthesize firstTaxNameLabel;
@synthesize secondTaxNameLabel;

- (id)initWithCoder:(NSCoder*)aDecoder
{
    if(self = [super initWithCoder:aDecoder]) {
        // Do something
        // set source and delegates
        quickCollectionView.delegate = self;
        quickCollectionView.dataSource = self;
        quickTableView.delegate = self;
        quickTableView.dataSource = self;
        
        // Set up the order.
        self.order = [[Orders alloc] init];
        
        // The current menu items are always Class Names first.
        //self.currentMenuItems = [[self database] classNames];
        self.currentMenuItems = [[NSMutableArray alloc] init];
        
        taxNameChanged = NO;
        
        // Holds previous menu arrays to jump backwards
        self.stackOfMenus = [[NSMutableArray alloc] init];
        self.stackOfIsSubclassBools = [[NSMutableArray alloc] init];
        self.stackOfIsActualItemBools = [[NSMutableArray alloc] init];
        self.selectedItemId = [[NSNumber alloc] init];
        
        
        [self setIsSubclass:FALSE];
        [self setIsActualItems:FALSE];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [self applyColorToBackgrounds];
    
    // set a response to one tap
    [oneFingerOneTap setNumberOfTapsRequired:1];
    [oneFingerOneTap setNumberOfTouchesRequired:1];
    
    // test on itemproperties
    NSString *itemTestid = [[NSString alloc] initWithFormat:@"%d", 74];
    ItemProperties *itemProperties = [[ItemProperties alloc] initWithItemId:itemTestid];
    
    // Initialize the labels to nothing.
    amountLabel.text = @"0";
    taxLabel.text = @"0";
    totalLabel.text = @"0";
    firstTaxLabel.text = @"0";
    secondTaxLabel.text = @"0";
    
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    // update the amount when coming back from choosing mods
    [self updateTotalOfOrderLabels];
}

- (void)applyColorToBackgrounds
{
    // Set up the background.
    //self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background2.png"]];
    self.view.backgroundColor = [UIColor grayColor];
    
    // view top right
    self.quickTopView.backgroundColor = [UIColor clearColor];
    self.quickTopView.layer.borderColor = [UIColor orangeColor].CGColor;
    self.quickTopView.layer.borderWidth = 2.0f;
    // table top left
    self.quickTableView.backgroundColor = [UIColor clearColor];
    self.quickTableView.layer.borderColor = [UIColor orangeColor].CGColor;
    self.quickTableView.layer.borderWidth = 2.0f;
    
    
    self.quickCollectionView.backgroundColor = [UIColor clearColor];
    
}

- (IBAction)flipBackMenuItems:(UIBarButtonItem *)sender
{
    if ([stackOfMenus count] == 0) {
        return;
    }
    // have a stack of arrays to go backwards
    currentMenuItems = [[NSMutableArray alloc] initWithArray:[stackOfMenus lastObject]];
    [stackOfMenus removeLastObject];
    
    self.isSubclass = [[stackOfIsSubclassBools lastObject] boolValue];
    [stackOfIsSubclassBools removeLastObject];
    
    self.isActualItems = [[stackOfIsActualItemBools lastObject] boolValue];
    [stackOfIsActualItemBools removeLastObject];
    
    [[self quickCollectionView] reloadData];
    [[self quickTableView] reloadData];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    //ignore any touches from a UIToolbar
    if ([touch.view.superview isKindOfClass:[UIToolbar class]]) {
        return NO;
    }
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)handleOneTap:(UITapGestureRecognizer *)sender
{
    CGPoint point = [sender locationInView:[self quickCollectionView]];
    NSIndexPath *indexPath = [self.quickCollectionView indexPathForItemAtPoint:point];
    self.nameOfSelected = [[self currentMenuItems] objectAtIndex:indexPath.row];
    
    /*
     When the QuickServe is first selected, the collection view only displays Class Names.
     if (subclass == false) AND (actualItems == false) do
     After clicking a Class, check to see if that class has a Subclass.
     To check if a Class has a Subclass, query the database and if the array returned is a 1, it means it doesn't have a subclass.
     If the selected Class doesn't have a subclass, go ahead and display the items.
     If it does have a Subclass, set the subclass variable to True and display Subclasses.
     else
     The else statement takes care of when Subclass is true, but actualItems aren't. It displays the Items
     by querying the database using the Subclass name as a parameter instead of a Classname. At this point, set the actualItems to true.
     Then refresh the view for the changes to take effect.
     */
    
    if (![self isSubclass] && ![self isActualItems]) {
        if ([[[self database] subclassWhereClassIs:self.nameOfSelected] count] == 1) {
            [self savePreviousState];
            [self setIsActualItems:TRUE];
            [self setIsSubclass:TRUE];
            [self setCurrentMenuItems:[[self database] itemsWhereClassIs:self.nameOfSelected]];
            self.classNameForDatabase = self.nameOfSelected;
        } else {
            [self savePreviousState];
            [self setIsSubclass:TRUE];
            self.classNameForDatabase = self.nameOfSelected;
            [self setCurrentMenuItems:[[self database] subclassWhereClassIs:self.nameOfSelected]];
        }
    } else if ([self isSubclass] && ![self isActualItems]) {
        [self savePreviousState];
        [self setCurrentMenuItems:[[self database] itemsWhereSubclassIs:self.nameOfSelected]];
        [self setIsActualItems:TRUE];
        self.subclassNameForDatabase = self.nameOfSelected;
    } else {
        // actual items, add to the order
        self.selectedItemId = [[self database] itemIdWhereClassIs:self.classNameForDatabase
                                                    andSubclassIs:self.subclassNameForDatabase
                                                        andItemIs:self.nameOfSelected];
        [self addAnOrder];
    }
    
    // refresh the screen with new menu items
    [[self quickCollectionView] reloadData];
    [[self quickTableView] reloadData];
}

- (void)addAnOrder
{
    // no mods, add the order to the model and update all views and labels
    [order addToOrder:self.selectedItemId];
    // update the total of the order visually
    [self updateTotalOfOrderLabels];
}

- (IBAction)modButtonPressed:(UIBarButtonItem *)sender
{
    // TODO: ADD A CHECK TO SEE IF THERE ARE ANY ORDERS AND NOT TO SEGUE IF THERE ARE NONE
    [self performSegueWithIdentifier:@"showModifiers" sender:self];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)updateTotalOfOrderLabels
{
    // update the model
    [order updateTotals];
    
    // get a decimal value to display currency
    NSNumberFormatter *numberFormater = [[NSNumberFormatter alloc] init];
    [numberFormater setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *nsTaxValue = [NSNumber numberWithDouble:([order.totalPrice doubleValue] - [order.totalAmount intValue])];
    NSNumber *nsAmtValue = [NSNumber numberWithDouble:[order.totalAmount doubleValue]];
    NSNumber *nsTotValue = [NSNumber numberWithDouble:[order.totalPrice doubleValue]];
    
    NSNumber *nsFTaxValue = [NSNumber numberWithDouble:
                             [nsTaxValue doubleValue] - ([order.totalAmount doubleValue] * [order.taxTwoPercentage doubleValue])];
    NSNumber *nsSTaxValue = [NSNumber numberWithDouble:
                             [nsTaxValue doubleValue] - ([order.totalAmount doubleValue] * [order.taxOnePercentage doubleValue])];
    
    // update the view
    amountLabel.text = [numberFormater stringFromNumber:nsAmtValue];
    taxLabel.text = [numberFormater stringFromNumber:nsTaxValue];
    totalLabel.text = [numberFormater stringFromNumber:nsTotValue];
    firstTaxLabel.text = [numberFormater stringFromNumber:nsFTaxValue];
    secondTaxLabel.text = [numberFormater stringFromNumber:nsSTaxValue];
    
    if(!taxNameChanged) {
        firstTaxNameLabel.text = order.nameOfFirstTax;
        secondTaxNameLabel.text = order.nameOfSecondTax;
        if ([order.nameOfFirstTax isEqualToString:@"Tax One"]) {
            taxNameChanged = NO;
        } else {
            taxNameChanged = YES;
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showModifiers"]) {
        QuickModifierController *destViewController = segue.destinationViewController;
        destViewController.delegate = self;
        destViewController.selectedItemId = self.selectedItemId;
        destViewController.database = self.database;
    } else if ([segue.identifier isEqualToString:@"paymentSegue"]) {
        PaymentTableViewController *destViewController = segue.destinationViewController;
        destViewController.tableNumber = tableNumber;
        destViewController.order = order;
    }
}

- (void)savePreviousState
{
    [[self stackOfMenus] addObject:currentMenuItems];
    [[self stackOfIsActualItemBools] addObject:[NSNumber numberWithBool:self.isActualItems]];
    [[self stackOfIsSubclassBools] addObject:[NSNumber numberWithBool:self.isSubclass]];
}

#pragma mark - Collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[self currentMenuItems] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /* The collection view cells get filled with names of classes like 'LUNCH'. */
    static NSString *CellIdentifier = @"quickServe";
    QuickServeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    int row = [indexPath row];
    NSString * menuItemName = [[self currentMenuItems] objectAtIndex:row];
    cell.itemLabel.text = menuItemName;
    [cell changeBorders:cell.frame];
    //NSLog(@"%@", cell.itemLabel.text);
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
   // NSLog(@"%d", [[self currentMenuItems] count]);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[order currentItemIds] count];
}

#define STEPPER_MAX_VALUE 20
#define STEPPER_MIN_VALUE 1

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"quickTableCell";
    QuickServeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Create a stepper that will handle the quantity of an item.
    UIStepper *stepperView = [[UIStepper alloc] initWithFrame:CGRectZero];
    cell.accessoryView = stepperView;
    stepperView.minimumValue = STEPPER_MIN_VALUE;
    stepperView.maximumValue = STEPPER_MAX_VALUE;
    stepperView.stepValue = 1;
    stepperView.wraps = YES;
    stepperView.autorepeat = YES;
    stepperView.continuous = YES;
    [stepperView addTarget:self action:@selector(stepperValueChanged:) forControlEvents:UIControlEventValueChanged];
    [stepperView release];
    
    stepperView.value = [[[order currentQtys] objectAtIndex:indexPath.row] doubleValue];
    
    cell.itemNameLabel.text = [[self database] getItemNameUsing:[[order currentItemIds] objectAtIndex:indexPath.row]];
    cell.priceLabel.text = [NSString stringWithFormat:@"$%@", [[self database] getLunchPriceUsing:[[order currentItemIds]
                                                                                                   objectAtIndex:indexPath.row]]];
    
    // currentQuantities returns an NSNumber, so convert it to a string while changing the label's text.
    cell.qtyLabel.text = [NSString stringWithFormat:@"%@", [[order currentQtys] objectAtIndex:indexPath.row]];
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    //UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, quickTableView.frame.size.width, 18)];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, quickTableView.frame.size.width, 20)];
    /* Create custom view to display section header... */
    //UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, quickTableView.frame.size.width, 18)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, quickTableView.frame.size.width, 20)];
    [label setFont:[UIFont boldSystemFontOfSize:12]];
    NSString *string = @"      Name                                                                   Price               Quantity       ";
    
    [label setText:string];
    [view addSubview:label];
    
    [label setBackgroundColor:[UIColor blueColor]];
    [view setBackgroundColor:[UIColor blackColor]];
    [label setBackgroundColor:[UIColor clearColor]];
    [view setBackgroundColor:[UIColor clearColor]];
    return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Change the selected item when clicking on the table.
    self.selectedItemId = [[order currentItemIds] objectAtIndex:indexPath.row];
    
    NSArray *stringModArray = [self.order.dictionary objectForKey:self.selectedItemId];
    
    // Display a list of modifiers if there is at least one modifier to display.
    if ([stringModArray count]) {
        PopUpModDescriptionViewController *popUpViewController = [[PopUpModDescriptionViewController alloc] initWithStyle:UITableViewStylePlain andArray:stringModArray];
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        CGRect rect=CGRectMake(cell.bounds.origin.x+300, cell.bounds.origin.y+10, 10, 30);
        popover = [[UIPopoverController alloc] initWithContentViewController:popUpViewController];
        [popover presentPopoverFromRect:rect inView:cell permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    
}

- (IBAction)stepperValueChanged:(UIStepper *)sender
{
    // Update the model with updated quantity, then display it.
    QuickServeTableCell *parentCell = (QuickServeTableCell *)sender.superview;
    NSIndexPath *indexPath = [self.quickTableView indexPathForCell:parentCell];
    [[order currentQtys] replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithInt:(int)sender.value]];
    parentCell.qtyLabel.text = [NSString stringWithFormat:@"%@", [[order currentQtys] objectAtIndex:indexPath.row]];
    
    // If the stepper reached the max value, it means the item should be removed from the table/order.
    // TODO: FIX BUG WHERE CLICKING THE STEPPER TOO FAST WILL SKIP THE IF STATEMENT
    if (sender.value == STEPPER_MAX_VALUE) {
        // remove the object from order model, update every label
        [[order dictionary] removeObjectForKey:[[order currentItemIds] objectAtIndex:indexPath.row]];
        [[order currentItemIds] removeObjectAtIndex:indexPath.row];
        [[order currentQtys] removeObjectAtIndex:indexPath.row];
        [[self quickTableView] reloadData];
        [self updateTotalOfOrderLabels];
    }
    [self updateTotalOfOrderLabels];
}

#pragma mark Quick Modifier Controller data source
- (void)changedModiferStringArray:(NSMutableArray *)updatedModifierStringArray withItemId:(NSNumber *)itemId
{
    [[self order] updateDictionaryWithModifierString:updatedModifierStringArray forKey:itemId];
}

- (BOOL)modTrueInDictionary:(NSNumber *)itemId withCellValue:(NSString *)cellValue
{
    return [[self order] nameInKey:cellValue ofKey:itemId];
}

- (void)dealloc
{
    [quickToolbar release];
    [modButton release];
    [quickTableView release];
    [totalLabel release];
    [taxLabel release];
    [amountLabel release];
    [firstTaxLabel release];
    [secondTaxLabel release];
    [firstTaxNameLabel release];
    [secondTaxNameLabel release];
    [popover release];
    [super dealloc];
}

- (IBAction)clickedConfirm:(UIBarButtonItem *)sender
{
    UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                           message:@"You've confirmed your order."
                                                          delegate:nil
                                                 cancelButtonTitle:@"Cancel"
                                                 otherButtonTitles:@"Pay Later", @"Pay Now", nil];
    successAlert.tag = 1;
    successAlert.delegate = self;
    [successAlert show];
    [successAlert release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 1) {
        // handle confirm
        if (buttonIndex == 0) {
            // cancel
        }
        
        if (buttonIndex == 1) {
            // pay later
            [self.navigationController popToRootViewControllerAnimated:YES]; // go back to the original screen
            //HomeViewController *hvc = (HomeViewController *) (self.navigationController.viewControllers[0]);
        }
        
        if (buttonIndex == 2) {
            // pay now
            [self performSegueWithIdentifier:@"paymentSegue" sender:self];
        }
    }
}

- (void)printStringsFromArray:(NSMutableArray *)array
{
    for (int i=0; i<[array count]; i++) {
        NSLog(@"%@", [array objectAtIndex:i]);
    }
}



@end

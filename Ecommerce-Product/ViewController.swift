//
//  ViewController.swift
//  Ecommerce-Product
//
//  Created by Kishan Ravindra on 15/07/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import UIKit

class ViewController: UIViewController,KASlideShowDelegate,SSRollingButtonScrollViewDelegate {

    @IBOutlet var productDetailsCollectionView: UICollectionView!
    @IBOutlet var productSlideView: KASlideShow!
    @IBOutlet var segmentControlView: UIView!
    let segmentController = HMSegmentedControl()
    @IBOutlet var coverFlowLayout: YRCoverFlowLayout!
    
    @IBOutlet weak var sizeScrollButton: SSRollingButtonScrollView!
    
    
    let sizeAndQuantityDataSource = ["1","2","3","4","5","6","7","8","9","10"]
   
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        productSlideView.backgroundColor = UIColor.clearColor()
    }
    
    //MARK:- Setting UI data for size and quantity
    func setItemSizeAndQuantityUIData(buttonScrollerName:SSRollingButtonScrollView) -> SSRollingButtonScrollView{
        buttonScrollerName.spacingBetweenButtons = 5
        buttonScrollerName.notCenterButtonTextColor = UIColor.darkGrayColor()
        buttonScrollerName.centerButtonTextColor = UIColor.redColor()
        buttonScrollerName.createButtonArrayWithButtonTitles(sizeAndQuantityDataSource, andLayoutStyle: SShorizontalLayout)
        buttonScrollerName.ssRollingButtonScrollViewDelegate = self
        return buttonScrollerName
    }
    

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        productSlideView.delegate = self
        productSlideView.delay = 0.1
        productSlideView.transitionDuration = 0.5
        productSlideView.transitionType = .SlideHorizontal
        productSlideView.contentMode = .ScaleAspectFill
    productSlideView.addImagesFromResources(["asics1.png","asics2.png","asics3.png"])
        showProductTypesInSegmentControl()
    }
    
    //MARK:- Creating segmentControl for different views of particular product
    func showProductTypesInSegmentControl(){
        segmentController.sectionImages = [UIImage(named: "asics1S.png")!,UIImage(named:"asics2S.png")!,UIImage(named:"asics3S.png")!]
        print(segmentController.sectionImages)
        segmentController.type = HMSegmentedControlTypeImages
        segmentController.autoresizingMask = [.FlexibleRightMargin, .FlexibleWidth]
        segmentController.frame = CGRectMake(0, 0,segmentControlView.frame.size.width, segmentControlView.frame.size.height)
        segmentController.segmentEdgeInset = UIEdgeInsetsMake(0, 10, 0, 10)
        segmentController.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe
        segmentController.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown
        segmentController.verticalDividerEnabled = true
        segmentController.verticalDividerColor = UIColor.whiteColor()
        segmentController.backgroundColor = UIColor.clearColor()
        segmentController.selectionIndicatorColor = UIColor.redColor()
        segmentController.selectionIndicatorHeight = 2.0
        segmentController.addTarget(self, action:#selector(ViewController.segmentedControlChangedValue(_:)), forControlEvents:.ValueChanged)
        segmentControlView.addSubview(segmentController)
    }

    //MARK:HMSegmentControl Delegate Method
    func segmentedControlChangedValue(segmentedControl:HMSegmentedControl)
    {
        productSlideView.moveToIndex(segmentController.selectedSegmentIndex)
        segmentController.userInteractionEnabled = false
    }
    
    //MARk:-KASlideShow Delegate
    func slideAnimationCompleted(){
        segmentController.userInteractionEnabled = true
    }
    
    //MARK:- SSRollingButton Delegate
    func rollingScrollViewButtonPushed(button: UIButton!, ssRollingButtonScrollView rollingButtonScrollView: SSRollingButtonScrollView!) {
        print(button.titleLabel?.text!)
    }
    
    func rollingScrollViewButtonIsInCenter(button: UIButton!, ssRollingButtonScrollView rollingButtonScrollView: SSRollingButtonScrollView!) {
        print(button.titleLabel?.text!)
    }
}

extension ViewController:UICollectionViewDelegate,UICollectionViewDataSource{
    // tell the collection view how many cells to make
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 2
    }
    
    // make a cell for each cell index path
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
    // get a reference to our storyboard cell
        let cell:CustonSecondCell
        if indexPath.item == 0 {
          cell  = collectionView.dequeueReusableCellWithReuseIdentifier("Cell1", forIndexPath: indexPath) as! CustonSecondCell
        }else{
             cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell2", forIndexPath: indexPath) as! CustonSecondCell
            cell.sizeScrollButton = setItemSizeAndQuantityUIData(cell.sizeScrollButton)
            cell.productScrollButton = setItemSizeAndQuantityUIData(cell.productScrollButton)
        }
        return cell
    }
}


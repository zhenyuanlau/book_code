//
//  ViewController.swift
//  PragmaticTweets
//
//  Created by Chris Adamson on 6/6/14.
//  Copyright (c) 2014 Pragmatic Programmers, LLC. All rights reserved.
//

import UIKit
import Social
import Accounts

// nasty global
let defaultAvatarURL = NSURL(string:
  "https://abs.twimg.com/sticky/default_profile_images/" +
  "default_profile_6_200x200.png")


class ViewController: UITableViewController {
  var parsedTweets : Array <ParsedTweet> = [
    ParsedTweet(tweetText:"iOS SDK Development now in print. " +
      "Swift programming FTW!",
      userName:"@pragprog",
      createdAt:"2014-08-20 16:44:30 EDT",
      userAvatarURL: defaultAvatarURL),
    
    ParsedTweet(tweetText:"Math is cool",
      userName:"@redqueencoder",
      createdAt:"2014-08-16 16:44:30 EDT",
      userAvatarURL: defaultAvatarURL),
    
    ParsedTweet(tweetText:"Anime is cool",
      userName:"@invalidname",
      createdAt:"2014-07-31 16:44:30 EDT",
      userAvatarURL: defaultAvatarURL)
    
  ]
  
  // comment out reloadTweets() in the following method to
  // leave table initially empty and force you to pull-to-refresh
  override func viewDidLoad() {
    super.viewDidLoad()
    reloadTweets()
    var refresher = UIRefreshControl()
    refresher.addTarget(self,
      action: "handleRefresh:",
      forControlEvents: UIControlEvents.ValueChanged)
    self.refreshControl = refresher
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @IBAction func handleTweetButtonTapped(sender : UIButton) {
    if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
      let tweetVC = SLComposeViewController (forServiceType: SLServiceTypeTwitter)
      let message = NSBundle.mainBundle().localizedStringForKey(
        "I just finished the first project in iOS SDK Development. #pragsios",
        value: "",
        table: nil)
      tweetVC.setInitialText(message)
      tweetVC.completionHandler = {
        (SLComposeViewControllerResult result) -> Void in
        if result == SLComposeViewControllerResult.Done {
          self.reloadTweets()
        }
      }
      self.presentViewController(tweetVC, animated: true, completion: nil)
    } else {
      println ("Can't send tweet")
    }
  }
  
  
  @IBAction func handleShowMyTweetsButtonTapped(sender : UIButton) {
    self.reloadTweets()
  }
  
  // MARK: Twitter API stuff
  
  func reloadTweets() {
    let accountStore = ACAccountStore()
    let twitterAccountType = accountStore.accountTypeWithAccountTypeIdentifier(
      ACAccountTypeIdentifierTwitter)
    accountStore.requestAccessToAccountsWithType(twitterAccountType,
      options: nil,
      completion: {
        (Bool granted, NSError error) -> Void in
        if (!granted) {
          println ("account access not granted")
        } else {
          let twitterAccounts = accountStore.accountsWithAccountType(twitterAccountType)
          if twitterAccounts.count == 0 {
            println ("no twitter accounts configured")
            return
          } else {
            let twitterParams = [
              "count" : "100"
            ]
            let twitterAPIURL = NSURL.URLWithString(
              "https://api.twitter.com/1.1/statuses/home_timeline.json")
            let request = SLRequest(forServiceType: SLServiceTypeTwitter,
              requestMethod:SLRequestMethod.GET,
              URL:twitterAPIURL,
              parameters:twitterParams)
            request.account = twitterAccounts[0] as ACAccount
            request.performRequestWithHandler ( {
              (NSData data, NSHTTPURLResponse urlResponse, NSError error) -> Void in
              self.handleTwitterData(data, urlResponse: urlResponse, error: error)
            })
          }
        }
    })
  }
  
  func handleTwitterData (data: NSData!,
    urlResponse: NSHTTPURLResponse!,
    error: NSError!) {
      if let dataValue = data {
        let jsonString = NSString (data: data, encoding:NSUTF8StringEncoding)
        var parseError : NSError? = nil
        let jsonObject : AnyObject? =
        NSJSONSerialization.JSONObjectWithData(dataValue,
          options: NSJSONReadingOptions(0),
          error: &parseError)
        if parseError != nil {
          return
        }
        if let jsonArray = jsonObject as? Array<Dictionary<String, AnyObject>> {
          self.parsedTweets.removeAll(keepCapacity: true)
          for tweetDict in jsonArray {
            let parsedTweet = ParsedTweet()
            parsedTweet.tweetText = tweetDict["text"]  as? NSString
            parsedTweet.createdAt = tweetDict["created_at"]  as? NSString
            let userDict = tweetDict["user"] as NSDictionary
            parsedTweet.userName = userDict["name"] as? NSString
            parsedTweet.userAvatarURL = NSURL (string:
              userDict ["profile_image_url"] as NSString!)
            self.parsedTweets.append(parsedTweet)
          }
          dispatch_async(dispatch_get_main_queue(),
            {() -> Void in
              self.tableView.reloadData()
          })
        }
      } else {
        println ("handleTwitterData received no data")
      }
  }
  
  //MARK: table data source
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_tableView: UITableView,
    numberOfRowsInSection section: Int) -> Int {
      return parsedTweets.count
  }
  
  override func tableView (_tableView: UITableView,
    cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCellWithIdentifier("CustomTweetCell")
        as ParsedTweetCell
      let parsedTweet = parsedTweets[indexPath.row]
      cell.userNameLabel.text = parsedTweet.userName
      cell.tweetTextLabel.text = parsedTweet.tweetText
      cell.createdAtLabel.text = parsedTweet.createdAt
      if parsedTweet.userAvatarURL != nil {
        /* fast, wrong version 

        dispatch_async(dispatch_get_global_queue(  
          DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), 
          {() -> Void in 
            let avatarImage = UIImage(data: NSData (
              contentsOfURL: parsedTweet.userAvatarURL!))
            dispatch_async(dispatch_get_main_queue(),  
              {
                cell.avatarImageView.image = avatarImage
            }) 
        }) 
        */

        /* fast, right version
        */
        cell.avatarImageView.image = nil
        dispatch_async(dispatch_get_global_queue(
          DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
          {() -> Void in
            let avatarImage = UIImage(data: NSData (
              contentsOfURL: parsedTweet.userAvatarURL!))
            dispatch_async(dispatch_get_main_queue(), 
              {
                if cell.userNameLabel.text == parsedTweet.userName {
                  cell.avatarImageView.image = avatarImage
                } else {
                  println ("oops, wrong cell, never mind")
                }
            }) 
        })
      }
      return cell
  }
  
  @IBAction func handleRefresh (sender : AnyObject?) {
    self.parsedTweets.append(
      ParsedTweet (tweetText: "New row",
        userName: "@refresh",
        createdAt: NSDate().description,
        userAvatarURL: defaultAvatarURL))
    reloadTweets()
    refreshControl!.endRefreshing()
  }
  
}


# iOS-Network-Interceptor
A set of classes that will allow you to monitor any request using NSURLConnection or NSURLSession.

# How to use

You can run the project, there is no UI controls, in the viewDidLoad method of the ViewController we use the XplatNetworkMonitorClient to start monitoring and adding self as NSNotificationCenter observer to the kXPLNetworkMonitorNotification key. When the metwork is intercpeted the selector networkDataIntercepted: is invoked.

# Pods

The Pods are included in the repository.
We use AFNetworking pod to test network interception.

# Tests

Using GRUnit testing framework for iOS. You could use XCTests, it's just a preference I have.
There are two tests, one testing the NSURLConnection API with AFNetworking and one for the NSURLSession API.

### Operation and OperationQueue in Swift

![Operation queue](https://koenig-media.raywenderlich.com/uploads/2018/05/OperationQueue-feature.png)

Everyone has had the frustrating experience of tapping a button or entering some text in an iOS or Mac app, when all of a sudden: WHAM! The user interface stops responding.
On the Mac, your users get to stare at the colorful wheel rotating for a while until they can interact with the UI again. In an iOS app, users expect apps to respond immediately to their touches. Unresponsive apps feel clunky and slow, and usually receive bad reviews.

Keeping your app responsive is easier said than done. Once your app needs to perform more than a handful of tasks, things get complicated quickly. There isn’t much time to perform heavy work in the main run loop and still provide a responsive UI.

What’s a poor developer to do? The solution is to move work off the main thread via concurrency. Concurrency means that your application executes multiple streams (or threads) of operations all at the same time. This way the user interface stays responsive as you’re performing your work.

One way to perform operations concurrently in iOS is with the Operation and OperationQueue classes. 

![Result](https://koenig-media.raywenderlich.com/uploads/2014/09/improved-700x350.png)

From [Ray Wenderlich](https://www.raywenderlich.com/190008/operation-and-operationqueue-tutorial-in-swift)
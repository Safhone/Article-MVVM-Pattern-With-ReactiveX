
# **Project Structure:**


## Application
**Application** contains `AppDelegate` & other files that *related to navigating in the app*. For example, `coodinator` etc.

## Networking
**Networking** contains service files that using to *request & response data from network (API)* or *access data from local database*. For example, `URLSession`, `Alarmofire`, `CoreData`, or `RealmDB` etc.

## **M***odels*
**Models** contains **2** sub-folders:
### Request
**Request** for *modeling request data to API*
### Response
**Response** for *modeling response data from API*
### **Note:**
**Request** models are using `Structure` with `encodable` for *encode* object to data.
**Response** models are using `Structure` with `decodable` for *decode* data to object.

## **V**iews
**Views** contains **2** sub-folders:
### - ViewControllers
**ViewControllers** contains *groups of ViewControllers & Storyboards*
### - CustomViews
**CustomViews** contain *groups of custom nib files* such as custom TableViewCell .etc
### **Note:**
In **ViewControllers**, there should be many sub-folders which contain pair of view controller & its storyboard.
In **CustomViews**, there also should be many sub-folders which names the same as the sub-folder in **ViewControllers** where the *custom nib files* is used.

## **V**iew**M**odels
**ViewModels** contains many sub-folders which names the same as the sub-folder in **ViewControllers** where the *ViewModel* is used.

## Utilities
**Utilities** contains **2** sub-folders:
### Libraries
**Libraries** contains *outside library* that is used in the project.
### Helpers
**Helpers** contain files that help developers to easily build the app such as custom TextField, Extension, and other more
### **Note:**
In **Libraries**, there should be only libraries that couldn't be use with CocoaPods.
In **Helpers**, sometimes could be messy without grouping, so feel free to group them the way you think that is easy for you.

## Resources
**Resourses** contains *assets* such as images that needed in the app.

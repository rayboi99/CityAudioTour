//
//  MapDelegate.swift
//  CityAudioTour
//
//  Created by Pichan Vasantakitkumjorn on 3/2/15.
//  Copyright (c) 2015 SE491-591. All rights reserved.
//

import Foundation
import MapKit


class MapDelegate:NSObject, MKMapViewDelegate, CLLocationManagerDelegate{
    //All variables for this class
    private let requestLocation:MKDirectionsRequest = MKDirectionsRequest()
    private let latitudeMeter:CLLocationDistance = 1500
    private let longitudeMeter:CLLocationDistance = 1500
    private let mapView:MainMapViewController!
    private let cameraController:CameraControl!
    private var currentLocation:CLLocation?
    private var camera:MKCoordinateRegion!
    private var isFindingCurrent = false
    private var needAttraction = true
    private var attractions:[Attraction]?
    private var isRouteSelected:Bool = false;
    
    //Models
    private var routesManager = RoutesManager.sharedInstance
    private var attractionsModel = AttractionsManager.sharedInstance
    
    //Need this constructor to create a super class (NSObject).
    override init(){
        super.init()
    }
    //Constructor for this class.
    init(mapView:MainMapViewController){
        self.mapView = mapView
        cameraController = CameraControl()
    }
    
    //Get current Location when locationManager.startUpdatingLocation() is called.
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if (locations != nil){
            currentLocation = locations[0] as? CLLocation
            if isFindingCurrent {
                camera = MKCoordinateRegionMakeWithDistance(currentLocation!.coordinate, latitudeMeter, longitudeMeter)
                mapView.mainMapView.setRegion(camera, animated: true)
                isFindingCurrent = false
            }
            manager.stopUpdatingLocation()
            
            if needAttraction{
                createPinPoint()
                needAttraction = false
            }
            
            
        }else{
            //Can't get data with some reason.
        }
    }
    
    //When we call addAnnotation of map view, this method will be called to modify each annotation style
    //on the map. We can modify to be our own images in the future if we want.
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            
            pinView!.canShowCallout = true
            pinView!.animatesDrop = true
            pinView!.pinColor = MKPinAnnotationColor.Green
            
            var calloutButton = UIButton.buttonWithType(.DetailDisclosure) as UIButton
            pinView!.rightCalloutAccessoryView = calloutButton
        }
        else{
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    //When the button in annotation is pressed, this method will be called to handle it.
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        self.mapView.gotoDetailPage(view)
    }
    
    //When we add overlay or polyline in the map, this method will be called to draw a polyline
    //in the map.
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        var renderer : MKPolylineRenderer! = nil
        if let overlay = overlay as? MKPolyline {
            renderer = MKPolylineRenderer(polyline:overlay)
            renderer.strokeColor = UIColor.blueColor().colorWithAlphaComponent(0.8)
            renderer.lineWidth = 2
        }
        return renderer
    }
    
    //Create all annotations on the map.
    private func createPinPoint(){
        //Clear all old annotation
        let oldAnnotationList = mapView.mainMapView.annotations
        mapView.mainMapView.removeAnnotations(oldAnnotationList)
        
        if let r = routesManager.selectedRoute{
            var attractionIDs = routesManager.selectedRoute?.AttractionIDs
            attractions = self.attractionsModel.GetAttractionsConcreteObjects(attractionIDs!)
            isRouteSelected = true
        }else{
            // Webservice call to get attractions
            attractions = attractionsModel.attractionsList
        }
        
        // loop through attractions
        for attraction in attractions!  {
            var pin = MKPointAnnotation()
            pin.title = attraction.AttractionName
            
            pin.coordinate.latitude = attraction.Latitude
            pin.coordinate.longitude = attraction.Longitude
            
            cameraController.setMinMaxCoordinate(pin.coordinate)
            
            // Add Pin to Map
            mapView.mainMapView.addAnnotation(pin)
        }
        
        cameraController.setMinMaxCoordinate(currentLocation!.coordinate)
        
        var camera = cameraController.calculateCenter()
        mapView.mainMapView.setRegion(camera, animated: true)
        
        cameraController.resetMinMax()
        
        mapView.mainMapView.setRegion(camera, animated: true)
        
        //Start creating route based on attraction list.
        createRoute()
    }
    
    //Creating route in the map based on attraction list.
    private func createRoute(){
        // remove existing route lines or overlays when this method starts
        var oldOverlays = mapView.mainMapView.overlays
        mapView.mainMapView.removeOverlays(oldOverlays)
        
        if isRouteSelected{
            // loop through attractions
            for attraction in attractions!  {
                // get flying distance
                let endingLocation = CLLocation(latitude: attraction.Latitude, longitude: attraction.Longitude)
                let distance = currentLocation!.distanceFromLocation(endingLocation)
                
                attraction.FlyingDistance = distance
            }
            
            attractions!.sort({ $0.FlyingDistance < $1.FlyingDistance })
            
            var counter = 0
            var prevMapItem = MKMapItem?()
            
            for attraction in attractions!  {
                
                // get walking distance
                
                let startingCoordinate = currentLocation!.coordinate
                let startingPlaceMark = MKPlacemark(coordinate: startingCoordinate, addressDictionary: nil)
                let startingMapItem = MKMapItem(placemark: startingPlaceMark)
                
                let endingCoordinate = CLLocationCoordinate2D(latitude: attraction.Latitude, longitude: attraction.Longitude)
                let endingPlaceMark = MKPlacemark(coordinate: endingCoordinate, addressDictionary: nil)
                let endingMapItem = MKMapItem(placemark: endingPlaceMark)
                
                if (counter != 0) {
                    requestLocation.setSource(prevMapItem)
                }else {
                    requestLocation.setSource(startingMapItem)
                }
                
                requestLocation.transportType = MKDirectionsTransportType.Walking
                requestLocation.requestsAlternateRoutes = false
                requestLocation.setDestination(endingMapItem)
                
                prevMapItem = endingMapItem
                
                // Call Directions API
                let direction:MKDirections = MKDirections(request:requestLocation)
                direction.calculateDirectionsWithCompletionHandler({
                    (response:MKDirectionsResponse!, error:NSError!) -> Void in
                    if response == nil {
                        println(error)
                        return
                    }
                    
                    let routeList = response.routes as [MKRoute]
                    
                    for route in routeList{
                        for step in route.steps as [MKRouteStep]{
                            self.mapView.mainMapView.addOverlay(step.polyline)
                        }
                        attraction.WalkingDistance = route.distance
                    }
                })
                counter = counter + 1
            }
            isRouteSelected = false
        }
    }
    
    func createSpecificPinPoint(selectedAttraction:String){
        var allRoutes = mapView.mainMapView.overlays
        mapView.mainMapView.removeOverlays(allRoutes)
        
        var selectedOne = attractionsModel.attractionsList.filter(
            {(attraction) -> Bool in return selectedAttraction == attraction.AttractionName})
        
        if !selectedOne.isEmpty{
            //Clear all old annotation
            let oldAnnotationList = mapView.mainMapView.annotations
            mapView.mainMapView.removeAnnotations(oldAnnotationList)
            //Create PinPoint for specific location
            var pin = MKPointAnnotation()
            pin.title = selectedOne[0].AttractionName
            pin.subtitle = "Hello is good"
            
            pin.coordinate.latitude = selectedOne[0].Latitude
            pin.coordinate.longitude = selectedOne[0].Longitude
            
            cameraController.setMinMaxCoordinate(pin.coordinate)
            
            mapView.mainMapView.addAnnotation(pin)
            
            cameraController.setMinMaxCoordinate(currentLocation!.coordinate)
            
            var camera = cameraController.calculateCenter()
            mapView.mainMapView.setRegion(camera, animated: true)
            
            cameraController.resetMinMax()
            
        }else{
            if objc_getClass("UIAlertController") != nil {
                var alert = UIAlertController(title: "Message", message: "No Result Was Found", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                mapView.presentViewController(alert, animated: true, completion: nil)
            }else{
                var alert = UIAlertView(title: "Message", message: "No Result Was Found", delegate: nil, cancelButtonTitle: "OK")
                alert.alertViewStyle = UIAlertViewStyle.Default
                alert.show()
            }
        }
    }

    func wantPinPoint(){
        needAttraction = true
    }
    
    func currentBtnisClicked(){
        isFindingCurrent = true
    }
    
}

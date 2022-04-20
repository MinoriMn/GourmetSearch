import UIKit
import Combine
import CombineCocoa
import MapKit
import CoreLocation
import FloatingPanel

class SearchViewController: UIViewController, CLLocationManagerDelegate, FloatingPanelControllerDelegate, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    private var searchBar: SearchBar!
    private var conditionViewController: ConditionViewController!
    private var searchResultFloatingPanelController: FloatingPanelController!
    private var searchResultViewController: SearchResultViewController!

    private var locationManager: CLLocationManager = CLLocationManager()

    private let viewModel: SearchViewModel = .init()
    private var cancellables: [AnyCancellable] = []

    private var pins: [ShopAnnotation] = []
    private var overlays: [MKOverlay] = []

    private let receiveSearchCondition = PassthroughSubject<SearchCondition, Never>()
    private let sendShopsResult = PassthroughSubject<[Shop], Never>()
    private let showRoute = PassthroughSubject<Shop?, Never>()
    private let selectedPin = PassthroughSubject<Int, Never>()

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        mapView.showsBuildings = true
        let category: [MKPointOfInterestCategory] = [.bakery, .brewery, .cafe, .foodMarket, .restaurant, .store, .winery]
        let filter = MKPointOfInterestFilter(excluding: category)
        mapView.pointOfInterestFilter = filter

        let conditionViewController = R.storyboard.conditionViewController.instantiateInitialViewController { [weak self] coder in
            guard let self = self else { return nil }
            return ConditionViewController(
                coder: coder,
                initSearchConditionPublisher: self.viewModel.sendSearchCondition.eraseToAnyPublisher(),
                searchConditionPublisher: self.receiveSearchCondition
            )
        } as! ConditionViewController
        self.conditionViewController = conditionViewController

        let searchResultViewController = R.storyboard.searchResultViewController.instantiateInitialViewController { [weak self] coder in
            guard let self = self else { return nil }
            return SearchResultViewController(
                coder: coder,
                shopsPublisher: self.sendShopsResult.eraseToAnyPublisher(),
                showRoute: self.showRoute,
                scrollToShop: self.viewModel.scrollToShop.eraseToAnyPublisher()
            )
        } as! SearchResultViewController
        self.searchResultViewController = searchResultViewController
        searchResultFloatingPanelController = FloatingPanelController()
        searchResultFloatingPanelController.delegate = self
        searchResultFloatingPanelController.set(contentViewController: self.searchResultViewController )
        searchResultFloatingPanelController.isRemovalInteractionEnabled = true

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

        let searchBar = SearchBar.make(condition: "")
        searchBar.frame.size = CGSize(width: 100.0, height: 100.0)
        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        let height = searchBar.heightAnchor.constraint(equalToConstant: 100.0)
        let top = searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        let left = searchBar.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16)
        let right = searchBar.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16)
        NSLayoutConstraint.activate([height, top, left, right])
        self.searchBar = searchBar

        bind(to: viewModel)
    }

    // 許可を求めるためのdelegateメソッド
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        // 許可されてない場合
        case .notDetermined:
            // 許可を求める
            manager.requestWhenInUseAuthorization()
        // 拒否されてる場合
        case .restricted, .denied: break
        // 許可されている場合
        case .authorizedAlways, .authorizedWhenInUse:
            // 現在地の取得を開始
            manager.startUpdatingLocation()
            Just(Void()).delay(for: .seconds(0.5), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    self?.closeToCurrentLocation(delta: 0.03)
                }
                .store(in: &cancellables)
        default: break
        }
    }

    private func bind(to viewModel: SearchViewModel) {
        showRoute
            .sink { [weak self] shop in
                guard let self = self,
                      let shop = shop,
                      let lat = shop.lat,
                      let lng = shop.lng else { return }
                  let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                self.setMapRoute(coordinate: coord)
            }
            .store(in: &cancellables)

        let search = receiveSearchCondition
            .map { [weak self] searchCondition -> (SearchCondition, CLLocationCoordinate2D?) in
                guard let self = self, let location = self.mapView.userLocation.location else {
                    return (searchCondition, nil)
                }
                return (searchCondition, location.coordinate)
            }
            .eraseToAnyPublisher()

        let output = viewModel.transform(
            input: .init(
                search: search,
                locationButtonTapped: locationButton.tapPublisher,
                conditionButtonTapped: searchBar.getConditionButtonTapPublisher(),
                searchResultButtonTapped: searchButton.tapPublisher,
                setectedPin: selectedPin.eraseToAnyPublisher()
            )
        )

        output.shops
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    print(error)
                }
            }, receiveValue: { [weak self] shops in
                guard let self = self else { return }

                // 件数表示
                self.searchButton.setTitle("\(shops.count)件", for: .normal)

                // ピン情報
                for pin in self.pins {
                    self.mapView.removeAnnotation(pin)
                }
                self.pins.removeAll()

                guard let foodImage = UIImage(systemName: "fork.knife") else { return }

                var newPins: [ShopAnnotation] = []
                for shop in shops {
                    guard let lat = shop.lat, let lng = shop.lng else { continue }
                    let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    let pin = ShopAnnotation(coord, glyphImage: foodImage, glyphTintColor: .white, markerTintColor: R.color.accentColor() ?? .orange)
                    pin.title = shop.name
                    newPins.append(pin)
                }
                self.pins = newPins
                self.mapView.showAnnotations(newPins, animated: true)

                self.sendShopsResult.send(shops)
            })
            .store(in: &cancellables)

        output.closeToCurrentLocation
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.closeToCurrentLocation(delta: 0.03)
            })
            .store(in: &cancellables)

        output.openSearchCondition
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.searchResultFloatingPanelController.removePanelFromParent(animated: true)
                self.conditionViewController.modalPresentationStyle = .pageSheet
                self.present(self.conditionViewController, animated: true)
            })
            .store(in: &cancellables)

        output.openSearchResult
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.searchResultFloatingPanelController.addPanel(toParent: self)
            })
            .store(in: &cancellables)

        Publishers.Merge(receiveSearchCondition, viewModel.sendSearchCondition.eraseToAnyPublisher())
            .receive(on: RunLoop.main)
            .sink { [weak self] searchCondition in
                self?.setConditionText(searchConditon: searchCondition)
            }
            .store(in: &cancellables)

        // 初期検索
        Just(()).delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.receiveSearchCondition.send(self.viewModel.searchCondition)
            }
            .store(in: &cancellables)
    }

    private func setMapRoute(coordinate: CLLocationCoordinate2D) {
        let directionsRequest = MKDirections.Request()
        guard let userCoordinate = mapView.userLocation.location?.coordinate else { return }
        let userPlaceMark = MKPlacemark(coordinate: userCoordinate)
        let placeMark = MKPlacemark(coordinate: coordinate)
        directionsRequest.transportType = .walking // TODO: 交通手段選択
        directionsRequest.source = MKMapItem(placemark: userPlaceMark)
        directionsRequest.destination = MKMapItem(placemark: placeMark)
        let direction = MKDirections(request: directionsRequest)
        direction.calculate(completionHandler: { [weak self] (response, error) in
            guard let self = self else { return }
            for overlay in self.overlays {
                self.mapView.removeOverlay(overlay)
            }
            self.overlays.removeAll()

            if error == nil, let myRoute = response?.routes[0] {
                self.mapView.addOverlay(myRoute.polyline, level: .aboveRoads) //mapViewに絵画
                self.overlays.append(myRoute.polyline)
            }

        })
    }

    private func closeToCurrentLocation(delta: Double) {
        if let coordinate = mapView.userLocation.location?.coordinate {
            closeToLocation(coordinate: coordinate, delta: delta)
        }
    }

    private func closeToLocation(coordinate: CLLocationCoordinate2D, delta: Double) {
        let span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }

    private func setConditionText(searchConditon: SearchCondition) {
        var text = "\(searchConditon.range.stringValue())"
        let includedBoolConditions = searchConditon.isLunch || searchConditon.isPet || searchConditon.isParking
        if let keyword = searchConditon.keyword {
            text += "で「\(keyword)」に関連する"
        } else {
            text += "の"
        }
        if includedBoolConditions {
            var isFirst = true
            if searchConditon.isLunch {
                text += "ランチあり"
                isFirst = false
            }
            if searchConditon.isPet {
                text += "\(isFirst ? "" : "・")ペット可"
                isFirst = false
            }
            if searchConditon.isParking {
                text += "\(isFirst ? "" : "・")駐車場有"
                isFirst = false
            }
            text += "な"
        }
        text += "お店"
        searchBar.setCondition(condition: text)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 現在位置なら何もしない
        if annotation is MKUserLocation {
            return nil
        }

        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: annotation)

        guard let markerAnnotationView = annotationView as? MKMarkerAnnotationView,
              let shopAnnotation = annotation as? ShopAnnotation else { return annotationView }

        markerAnnotationView.clusteringIdentifier = ShopAnnotation.clusteringIdentifier
        markerAnnotationView.glyphImage = shopAnnotation.glyphImage
        markerAnnotationView.glyphTintColor = shopAnnotation.glyphTintColor
        markerAnnotationView.markerTintColor = shopAnnotation.markerTintColor

        return markerAnnotationView
   }

    //ピンを繋げている線の幅や色を調整
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let route: MKPolyline = overlay as! MKPolyline
        let routeRenderer = MKPolylineRenderer(polyline: route)
        routeRenderer.strokeColor = R.color.accentColor() ?? .orange
        routeRenderer.lineWidth = 3.0
        return routeRenderer
    }

    // タップされたピンの情報
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation {

            if let shopAnnotation = annotation as? ShopAnnotation,
                let index = pins.firstIndex(of: shopAnnotation) {
                selectedPin.send(index)
            } else if let clusterAnnotation = annotation as? MKClusterAnnotation,
                      let shopAnnotation = clusterAnnotation.memberAnnotations.first as? ShopAnnotation,
                      let index = pins.firstIndex(of: shopAnnotation){
                selectedPin.send(index)
            }
        }
    }
}

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
    private var floatingPanelController: FloatingPanelController!

    private var locationManager: CLLocationManager = CLLocationManager()

    private let viewModel: SearchViewModel = .init()
    private var cancellables: [AnyCancellable] = []

    private var pins: [ShopAnnotation] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        mapView.showsBuildings = true
        let category: [MKPointOfInterestCategory] = [.bakery, .brewery, .cafe, .foodMarket, .restaurant, .store, .winery]
        let filter = MKPointOfInterestFilter(excluding: category)
        mapView.pointOfInterestFilter = filter

        floatingPanelController = FloatingPanelController()
        floatingPanelController.delegate = self
        floatingPanelController.set(contentViewController: ConditionViewController())
        floatingPanelController.isRemovalInteractionEnabled = true

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

        let searchBar = SearchBar.make(condition: "aaaaaa")
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
        // TODO
        let search = searchBar.getConditionButtonTapPublisher()
            .map { [weak self] _ -> CLLocationCoordinate2D? in
                guard let self = self, let location = self.mapView.userLocation.location else {
                    return nil
                }
                return location.coordinate
            }
            .eraseToAnyPublisher()

        let output = viewModel.transform(
            input: .init(
                search: search,
                locationButtonTapped: locationButton.tapPublisher,
                conditionButtonTapped: searchBar.getConditionButtonTapPublisher(),
                searchResultButtonTapped: searchButton.tapPublisher
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
                self.searchButton.titleLabel?.text = "\(shops.count)件"

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
                    let pin = ShopAnnotation(coord, glyphImage: foodImage, glyphTintColor: .white, markerTintColor: .orange)
                    pin.title = shop.name
                    newPins.append(pin)
                }
                self.pins = newPins
                self.mapView.showAnnotations(newPins, animated: true)
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
                self.floatingPanelController.addPanel(toParent: self)
            })
            .store(in: &cancellables)
    }

    private func closeToCurrentLocation(delta: Double) {
        if let coordinate = mapView.userLocation.location?.coordinate {
            let span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
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
}

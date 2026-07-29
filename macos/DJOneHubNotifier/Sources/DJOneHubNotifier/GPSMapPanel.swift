import AppKit
import MapKit

@MainActor
final class GPSMapPanel: NSObject, NSWindowDelegate {
    private let panel: NSPanel
    private let mapView = MKMapView()
    private let statusLabel = NSTextField(labelWithString: "正在搜索卫星")
    private let detailLabel = NSTextField(labelWithString: "模块取得有效定位后会自动显示当前位置")
    private let overlay = NSVisualEffectView()
    private var marker: MKPointAnnotation?

    override init() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 390),
            styleMask: [.titled, .closable, .utilityWindow, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        super.init()
        panel.title = "DJOneHub GPS"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.delegate = self
        buildContent()
    }

    func show() {
        positionAtTopRight()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        panel.orderOut(nil)
    }

    func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    func update(with fix: GPSFixSummary?) {
        guard let fix,
              let latitude = Self.coordinate(fix.latitude, valid: -90...90),
              let longitude = Self.coordinate(fix.longitude, valid: -180...180)
        else {
            showSearchingState()
            return
        }

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = marker ?? MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "DJOneHub GPS"
        if marker == nil {
            marker = annotation
            mapView.addAnnotation(annotation)
        }
        overlay.isHidden = true
        statusLabel.stringValue = "当前位置"
        detailLabel.stringValue = "已根据模块最新卫星定位更新"
        mapView.setRegion(
            MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 650,
                longitudinalMeters: 650
            ),
            animated: true
        )
    }

    private func buildContent() {
        let root = NSVisualEffectView()
        root.material = .sidebar
        root.blendingMode = .behindWindow
        root.state = .active
        root.wantsLayer = true
        root.layer?.cornerRadius = 16
        root.layer?.masksToBounds = true
        root.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = root

        let header = NSVisualEffectView()
        header.material = .headerView
        header.blendingMode = .withinWindow
        header.state = .active
        header.translatesAutoresizingMaskIntoConstraints = false

        let title = NSTextField(labelWithString: "GPS 实时位置")
        title.font = .systemFont(ofSize: 14, weight: .semibold)
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.textColor = .secondaryLabelColor
        detailLabel.font = .systemFont(ofSize: 12)
        detailLabel.textColor = .secondaryLabelColor

        let headerStack = NSStackView(views: [title, statusLabel, detailLabel])
        headerStack.orientation = .vertical
        headerStack.alignment = .leading
        headerStack.spacing = 3
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerStack)

        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.wantsLayer = true
        mapView.layer?.cornerRadius = 12
        mapView.layer?.masksToBounds = true

        overlay.material = .popover
        overlay.blendingMode = .withinWindow
        overlay.state = .active
        overlay.wantsLayer = true
        overlay.layer?.cornerRadius = 12
        overlay.translatesAutoresizingMaskIntoConstraints = false
        let searchTitle = NSTextField(labelWithString: "正在搜索卫星")
        searchTitle.font = .systemFont(ofSize: 13, weight: .semibold)
        let searchCopy = NSTextField(wrappingLabelWithString: "校准完成后自动显示当前位置")
        searchCopy.font = .systemFont(ofSize: 12)
        searchCopy.textColor = .secondaryLabelColor
        searchCopy.maximumNumberOfLines = 2
        let searchStack = NSStackView(views: [searchTitle, searchCopy])
        searchStack.orientation = .vertical
        searchStack.alignment = .centerX
        searchStack.spacing = 5
        searchStack.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(searchStack)

        root.addSubview(header)
        root.addSubview(mapView)
        root.addSubview(overlay)
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            header.topAnchor.constraint(equalTo: root.topAnchor),
            header.heightAnchor.constraint(equalToConstant: 88),
            headerStack.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 62),
            headerStack.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -18),
            headerStack.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -12),
            mapView.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 10),
            mapView.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -10),
            mapView.topAnchor.constraint(equalTo: header.bottomAnchor),
            mapView.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -10),
            overlay.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            overlay.centerYAnchor.constraint(equalTo: mapView.centerYAnchor),
            overlay.widthAnchor.constraint(equalToConstant: 240),
            searchStack.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 18),
            searchStack.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -18),
            searchStack.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 16),
            searchStack.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -16),
        ])
    }

    private func positionAtTopRight() {
        guard let screen = panel.screen ?? NSScreen.main ?? NSScreen.screens.first else { return }
        let frame = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(x: frame.maxX - panel.frame.width - 18, y: frame.maxY - panel.frame.height - 18))
    }

    private func showSearchingState() {
        if let marker {
            mapView.removeAnnotation(marker)
            self.marker = nil
        }
        statusLabel.stringValue = "正在搜索卫星"
        detailLabel.stringValue = "等待模块完成 GPS 校准"
        overlay.isHidden = false
    }

    private static func coordinate(_ raw: String?, valid range: ClosedRange<Double>) -> CLLocationDegrees? {
        guard let raw, let value = Double(raw.trimmingCharacters(in: .whitespacesAndNewlines)), range.contains(value) else {
            return nil
        }
        return value
    }
}

import UIKit
import PhotosUI
import UniformTypeIdentifiers
import CoreImage
import AVFoundation

extension ScanViewController: PHPickerViewControllerDelegate {
    @objc func pickCodeImage() {
        pauseCamera()
        var configuration = PHPickerConfiguration(); configuration.filter = .images; configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration); picker.delegate = self
        present(picker, animated: true)
    }
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
            guard let data else { Task { @MainActor in self?.showToast("图片无法读取，请重新选择") }; return }
            do {
                let text = try ScanImageReader.text(in: data)
                Task { @MainActor in self?.handleScannedText(text) }
            } catch { let message = error.localizedDescription; Task { @MainActor in self?.showToast(message) } }
        }
    }
}

nonisolated final class ScanCameraInput: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    let session = AVCaptureSession()
    var onText: ((String) -> Void)?
    private var configured = false
    private let queue = DispatchQueue(label: "ABank.scan.camera")
    func start() {
        queue.async { [weak self] in
            guard let self else { return }
            if !self.configured {
                guard let device = AVCaptureDevice.default(for: .video), let input = try? AVCaptureDeviceInput(device: device), self.session.canAddInput(input) else { return }
                self.session.beginConfiguration(); self.session.addInput(input)
                let output = AVCaptureMetadataOutput()
                guard self.session.canAddOutput(output) else { self.session.commitConfiguration(); return }
                self.session.addOutput(output); output.setMetadataObjectsDelegate(self, queue: .main)
                output.metadataObjectTypes = [.qr]; self.session.commitConfiguration(); self.configured = true
            }
            if !self.session.isRunning { self.session.startRunning() }
        }
    }
    func stop() { queue.async { [weak self] in if self?.session.isRunning == true { self?.session.stopRunning() } } }
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let text = (metadataObjects.first as? AVMetadataMachineReadableCodeObject)?.stringValue { onText?(text) }
    }
}

nonisolated enum ScanImageReader {
    enum ReadError: LocalizedError {
        case invalidImage, unavailable
        var errorDescription: String? { self == .invalidImage ? "图片无法读取，请重新选择" : "图片识别暂不可用，请尝试相机扫描" }
    }
    static func text(in data: Data) throws -> String? {
        guard let image = CIImage(data: data, options: [.applyOrientationProperty: true]) else { throw ReadError.invalidImage }
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else { throw ReadError.unavailable }
        return detector.features(in: image).compactMap { ($0 as? CIQRCodeFeature)?.messageString }.first
    }
}

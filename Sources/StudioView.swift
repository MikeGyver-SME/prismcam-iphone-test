import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos

private enum Look: String, CaseIterable, Identifiable {
    case original = "Original"
    case noir = "Noir"
    case warm = "Warm"
    case vivid = "Vivid"

    var id: String { rawValue }

    func apply(to photo: UIImage) -> UIImage {
        guard self != .original, let source = CIImage(image: photo) else { return photo }
        let filter: CIFilter
        switch self {
        case .original: return photo
        case .noir:
            filter = CIFilter.photoEffectNoir()
        case .warm:
            let sepia = CIFilter.sepiaTone()
            sepia.intensity = 0.75
            filter = sepia
        case .vivid:
            let color = CIFilter.colorControls()
            color.saturation = 1.65
            color.contrast = 1.13
            filter = color
        }
        filter.setValue(source, forKey: kCIInputImageKey)
        let context = CIContext()
        guard let output = filter.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else { return photo }
        return UIImage(cgImage: cgImage, scale: photo.scale, orientation: photo.imageOrientation)
    }
}

struct StudioView: View {
    @State private var photo: UIImage?
    @State private var look: Look = .original
    @State private var isCameraOpen = false
    @State private var status = "Your next shot starts here."

    private var editedPhoto: UIImage? { photo.map { look.apply(to: $0) } }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, Color(red: 0.13, green: 0.10, blue: 0.24)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Image(systemName: "camera.filters").font(.title)
                            .foregroundStyle(.mint)
                        Spacer()
                        Text("MIKEGYVER STUDIO").font(.caption.bold()).tracking(2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Text("PrismCam").font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Capture a moment. Change its mood.")
                        .foregroundStyle(.white.opacity(0.75))
                    ZStack {
                        RoundedRectangle(cornerRadius: 26).fill(.white.opacity(0.08))
                        if let editedPhoto {
                            Image(uiImage: editedPhoto).resizable().scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 26))
                        } else {
                            VStack(spacing: 15) {
                                Image(systemName: "viewfinder").font(.system(size: 70, weight: .ultraLight))
                                Text("A blank canvas, for now").font(.headline)
                            }.foregroundStyle(.white.opacity(0.55))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 350)
                    .accessibilityLabel(photo == nil ? "No photo yet" : "Photo with \(look.rawValue) effect")

                    if photo != nil {
                        Text("CHOOSE A LOOK").font(.caption.bold()).tracking(2).foregroundStyle(.white.opacity(0.65))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Look.allCases) { candidate in
                                    Button(candidate.rawValue) { look = candidate }
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 19).padding(.vertical, 12)
                                        .background(look == candidate ? Color.mint : Color.white.opacity(0.12), in: Capsule())
                                        .foregroundStyle(look == candidate ? .black : .white)
                                }
                            }
                        }
                    }
                    HStack(spacing: 12) {
                        Button { isCameraOpen = true } label: {
                            Label(photo == nil ? "Open Camera" : "Retake", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(StudioButtonStyle(tint: .mint, foreground: .black))
                        if photo != nil {
                            Button(action: save) {
                                Label("Save", systemImage: "square.and.arrow.down")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(StudioButtonStyle(tint: .white.opacity(0.16), foreground: .white))
                        }
                    }
                    Text(status).font(.footnote).foregroundStyle(.white.opacity(0.72))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(24)
            }
        }
        .sheet(isPresented: $isCameraOpen) {
            CameraView { captured in
                photo = captured
                look = .original
                status = "Photo captured. Choose a look, then save."
            }
            .ignoresSafeArea()
        }
    }

    private func save() {
        guard let image = editedPhoto else { return }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { authorization in
            guard authorization == .authorized || authorization == .limited else {
                DispatchQueue.main.async { status = "Allow photo saving in Settings to save your shot." }
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    status = success ? "Saved to Photos." : "Couldn't save: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        }
    }
}

private struct StudioButtonStyle: ButtonStyle {
    let tint: Color
    let foreground: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.bold())
            .padding(.vertical, 17)
            .background(tint.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 17))
            .foregroundStyle(foreground)
    }
}

private struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture, dismiss: dismiss) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onCapture: (UIImage) -> Void
        let dismiss: DismissAction
        init(onCapture: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let photo = info[.originalImage] as? UIImage { onCapture(photo) }
            dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { dismiss() }
    }
}

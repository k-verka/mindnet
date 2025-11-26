//
//  PhotoManager.swift
//  mindnet
//
//  Created by wv on 26/11/2025.
//

import SwiftUI
import PhotosUI

/// Менеджер для работы с фотографиями
@Observable
class PhotoManager {
    static let shared = PhotoManager()
    
    private let fileManager = FileManager.default
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private init() {
        createPhotosDirectoryIfNeeded()
    }
    
    // MARK: - Directory Management
    
    private func createPhotosDirectoryIfNeeded() {
        let photosURL = documentsURL.appendingPathComponent("Photos", isDirectory: true)
        if !fileManager.fileExists(atPath: photosURL.path) {
            try? fileManager.createDirectory(at: photosURL, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Save Photo
    
    /// Сохраняет UIImage и возвращает путь к файлу
    func savePhoto(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let filename = UUID().uuidString + ".jpg"
        let fileURL = documentsURL.appendingPathComponent("Photos").appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return filename  // Возвращаем только имя файла
        } catch {
            print("Error saving photo: \(error)")
            return nil
        }
    }
    
    /// Сохраняет несколько фото
    func savePhotos(_ images: [UIImage]) -> [String] {
        return images.compactMap { savePhoto($0) }
    }
    
    // MARK: - Load Photo
    
    /// Загружает UIImage по имени файла
    func loadPhoto(_ filename: String) -> UIImage? {
        let fileURL = documentsURL.appendingPathComponent("Photos").appendingPathComponent(filename)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    /// Создаёт URL для SwiftUI Image
    func getPhotoURL(_ filename: String) -> URL {
        return documentsURL.appendingPathComponent("Photos").appendingPathComponent(filename)
    }
    
    // MARK: - Delete Photo
    
    /// Удаляет фото по имени файла
    func deletePhoto(_ filename: String) {
        let fileURL = documentsURL.appendingPathComponent("Photos").appendingPathComponent(filename)
        try? fileManager.removeItem(at: fileURL)
    }
    
    /// Удаляет несколько фото
    func deletePhotos(_ filenames: [String]) {
        filenames.forEach { deletePhoto($0) }
    }
    
    // MARK: - Helpers
    
    /// Получает размер фото в байтах
    func getPhotoSize(_ filename: String) -> Int64? {
        let fileURL = documentsURL.appendingPathComponent("Photos").appendingPathComponent(filename)
        
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? Int64 else {
            return nil
        }
        
        return fileSize
    }
}

// MARK: - Photo Picker

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    var selectionLimit: Int = 5
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = selectionLimit
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard !results.isEmpty else { return }
            
            var loadedImages: [UIImage] = []
            let group = DispatchGroup()
            
            for result in results {
                group.enter()
                
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    defer { group.leave() }
                    
                    if let image = object as? UIImage {
                        loadedImages.append(image)
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.parent.images = loadedImages
            }
        }
    }
}

// MARK: - Photo Grid View

struct PhotoGridView: View {
    let photoPaths: [String]
    var onDelete: ((String) -> Void)?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(photoPaths, id: \.self) { path in
                PhotoThumbnailView(photoPath: path, onDelete: onDelete)
            }
        }
    }
}

struct PhotoThumbnailView: View {
    let photoPath: String
    var onDelete: ((String) -> Void)?
    
    @State private var image: UIImage?
    @State private var showingFullScreen = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        showingFullScreen = true
                    }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay {
                        ProgressView()
                    }
            }
            
            if let onDelete = onDelete {
                Button(action: { onDelete(photoPath) }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white)
                        .background(Circle().fill(Color.red))
                        .font(.title3)
                }
                .offset(x: 5, y: -5)
            }
        }
        .onAppear {
            loadImage()
        }
        .sheet(isPresented: $showingFullScreen) {
            if let image = image {
                FullScreenPhotoView(image: image)
            }
        }
    }
    
    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let loadedImage = PhotoManager.shared.loadPhoto(photoPath) {
                DispatchQueue.main.async {
                    self.image = loadedImage
                }
            }
        }
    }
}

struct FullScreenPhotoView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Add Photos Button

struct AddPhotosButton: View {
    @Binding var selectedImages: [UIImage]
    @State private var showingPicker = false
    var selectionLimit: Int = 5
    
    var body: some View {
        Button(action: { showingPicker = true }) {
            Label("Добавить фото", systemImage: "photo.badge.plus")
        }
        .sheet(isPresented: $showingPicker) {
            PhotoPicker(images: $selectedImages, selectionLimit: selectionLimit)
        }
    }
}

#Preview("Photo Grid") {
    PhotoGridView(photoPaths: ["test1.jpg", "test2.jpg", "test3.jpg"])
        .padding()
}

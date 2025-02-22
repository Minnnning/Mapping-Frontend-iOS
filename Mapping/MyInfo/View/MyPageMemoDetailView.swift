import SwiftUI
import MapKit

struct MyPageMemoDetailView: View {
    let id: Int
    @StateObject private var viewModel = MyPageMemoDetailViewModel()
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) var dismiss // 삭제 후 화면 닫기용
    
    @State private var isPhotoViewerPresented = false
    @State private var selectedImageURL: String?
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if let detail = viewModel.memoDetail {
                    // 제목과 작성자 정보
                    HStack(spacing: 10) {
                        VStack(alignment: .leading) {
                            Text(detail.title)
                                .font(.title)
                                .fontWeight(.bold)
                            if let datePart = detail.date.split(separator: ":").first {
                                HStack{
                                    Text(datePart).font(.caption2).foregroundStyle(.secondary)
                                    if detail.certified {
                                        Image(systemName: "checkmark.seal.fill").font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        Spacer()
                        
                        HStack {
                            ProfileImageView(imageURL: detail.profileImage)
                                .frame(width: 40, height: 40)
                            Text(detail.nickname)
                                .font(.subheadline)
                        }
                    }
                    
                    Divider()
                    
                    // 본문 내용
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading) {
                            Text(detail.content)
                                .font(.body)
                            
                            if let images = detail.images, !images.isEmpty {
                                ImageScrollView(images: images) { tappedImageURL in
                                        selectedImageURL = nil
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            selectedImageURL = tappedImageURL
                                        }
                                    }
                            }
                            Map(position: $position) {
                                Marker("", coordinate: CLLocationCoordinate2D(latitude: detail.lat, longitude: detail.lng))
                            }
                            .frame(height: 300)
                            .cornerRadius(10)
                        }
                    }
                } else {
                    Text("Failed to load memo details.")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .navigationBarTitle(Text("상세보기"), displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if let memo = viewModel.memoDetail {
                            NavigationLink(destination: MyMemoEditView(memo: memo)) {
                                Label("메모 수정", systemImage: "pencil")
                            }
                        }
                        Button(action: {
                            viewModel.deleteMemo(id: id, token: userManager.accessToken) {
                                dismiss()
                            }
                        }) {
                            Label("메모 삭제", systemImage: "trash")
                        }
                    } label: {
                        Label("edit", systemImage: "ellipsis.circle")
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
            .onAppear {
                viewModel.fetchMemoDetail(id: id, token: userManager.accessToken)
            }
            .onReceive(viewModel.$memoDetail) { newValue in
                if let detail = newValue {
                    position = .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: detail.lat, longitude: detail.lng),
                        span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
                    ))
                }
            }

        }
        .fullScreenCover(isPresented: $isPhotoViewerPresented) {
            if let selectedImageURL = selectedImageURL {
                PhotoView(imageURL: selectedImageURL, isPresented: $isPhotoViewerPresented)
            }
        }
        .onChange(of: selectedImageURL) { _, newValue in
            if newValue != nil {
                isPhotoViewerPresented = true
            }
        }
    }
}

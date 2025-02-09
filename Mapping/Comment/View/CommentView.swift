import SwiftUI

struct CommentView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var comment: Comment = Comment()
    @State private var isShaking: Bool = false // 애니메이션 상태 변수 추가
    @State private var updateComment: Bool = false
    
    @Binding var editingComment: Int
    @State var commentID: Int
    @Binding var update: Bool
    
    var body: some View {
        if editingComment != commentID {
            HStack(alignment: .top) {
                ProfileImageView(imageURL: comment.profileImageUrl)
                    .frame(width: 25, height: 25)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(comment.nickname)
                            .font(.headline)
                        
                        HStack(spacing: 1) {
                            ForEach(0..<comment.rating, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption2)
                            }
                        }
                        
                        Spacer()
                        
                        if comment.nickname == userManager.userInfo?.nickname {
                            Menu {
                                Button("수정") {
                                    editingComment = commentID
                                }
                                Button("삭제") {
                                    deleteComment(id: comment.id)
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.cBlack)
                            }
                        }
                    }
                    
                    Text(comment.comment)
                        .font(.body)
                    
                    HStack {
                        Text(comment.updatedAt)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if comment.modify == true {
                            Text("(수정됨)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        // 좋아요 버튼
                        Button(action: {
                            // 흔들림 애니메이션 트리거
                            isShaking = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isShaking = false
                                updateComment = true
                            }
                            
                            LikeHateService.likeComment(id: comment.id, accessToken: userManager.accessToken) { result in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success:
                                        print("Successfully liked the post.")
                                        updateComment = false
                                        
                                    case .failure(let error):
                                        print("Failed to like the post: \(error)")
                                    }
                                }
                            }
                        }) {
                            HStack(alignment: .bottom) {
                                Text("👍 \(comment.likeCnt)")
                                    .font(.caption)
                                    .foregroundColor(.cBlack)
                            }
                            .rotationEffect(isShaking ? Angle(degrees: -15) : Angle(degrees: 0))
                            .animation(isShaking ? Animation.easeInOut(duration: 0.1).repeatCount(5, autoreverses: true) : .default, value: isShaking)
                        }
                    }
                }
            }
            .onAppear(perform: fetchComment)
            .onChange(of: updateComment, { oldValue, newValue in
                if updateComment {
                    fetchComment()
                    //updateComment = false
                }
            })
        } else if (commentID == editingComment){
            CommentEditView(editingComment: $editingComment, updateComment: $updateComment, editingCommentId: commentID, editingCommentString: comment.comment, editingRating: comment.rating, editingTime: comment.updatedAt)
        }
    }
    
    private func fetchComment() {
        guard let url = URL(string: "https://api.mapping.kro.kr/api/v2/comment/\(commentID)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch comments: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(CommentResponse.self, from: data)
                if decodedResponse.success, let fetchedComment = decodedResponse.data {
                    DispatchQueue.main.async {
                        self.comment = fetchedComment
                    }
                }
            } catch {
                print("Failed to decode JSON: \(error)")
            }
        }.resume()
    }
    
    private func deleteComment(id: Int) {
        
        let urlString = "https://api.mapping.kro.kr/api/v2/comment/\(id)"
        guard let url = URL(string: urlString) else { return }
        print(userManager.accessToken)
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(userManager.accessToken)", forHTTPHeaderField: "Authorization")
        
        Task {
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                print("Comment deleted successfully.")
                update = true
            } catch {
                print("Error deleting comment: \(error)")
            }
        }
    }
}

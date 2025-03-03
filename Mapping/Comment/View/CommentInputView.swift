import SwiftUI

struct CommentInputView: View {
    @EnvironmentObject var userManager: UserManager
    @StateObject private var viewModel = CommentInputViewModel()
    let memoId: Int
    @Binding var update: Bool
    
    var body: some View {
        HStack() {
            TextField("댓글을 입력하세요", text: $viewModel.newComment)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Spacer()
            
            Button(action: {
                viewModel.addComment(memoId: memoId, userManager: userManager) {
                    update = true
                }
            }) {
                Text("등록")
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(viewModel.isCommentValid ? Color.pastelAqua : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!viewModel.isCommentValid)
        }
    }
}

#Preview {
    CommentInputView(memoId: 1, update: .constant(false))
}


// 별점
//                ForEach(1...5, id: \.self) { star in
//                    Image(systemName: star <= viewModel.rating ? "star.fill" : "star")
//                        .resizable()
//                        .frame(width: 20, height: 20)
//                        .foregroundColor(star <= viewModel.rating ? .yellow : .gray)
//                        .onTapGesture {
//                            viewModel.rating = star
//                        }
//                }

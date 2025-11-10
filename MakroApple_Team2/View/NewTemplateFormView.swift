import SwiftUI
import Foundation

struct NewTemplateFormView: View {
    
    @State private var formPesanan = ""
    @State private var viewModel = NewTemplateViewModel()
    @EnvironmentObject var session: SessionManager
    @Binding var path: NavigationPath
    @State private var keyboardVisible = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom){
                ScrollView{
                    VStack(alignment: .leading){
                        HStack{
                            Text("Masukan/Buat Formulir Pesanan")
                                .font(.title3)
                                .fontWeight(.bold)
                            Spacer()
                            Button(action: {
                                if let clipboard = UIPasteboard.general.string {
                                    formPesanan = clipboard
                                }
                            }) {
                                Label("Tempel", systemImage: "list.clipboard.fill")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(8)
                                    .labelStyle(.titleAndIcon)
                                    .foregroundColor(.white)
                                    .background(.blue)
                                    .cornerRadius(20)
                            }
                        }
                    
                        TextEditor(text: $formPesanan)
                            .padding(3)
                            .frame(height: geometry.size.height / 3)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(5), lineWidth: 0.5)
                            )
                            .overlay(
                                Group {
                                    if formPesanan.isEmpty && !keyboardVisible {
                                        Text("""
                                    Paste or write your Form Order here ✨(e.g. for your F&B or custom order form)

                                        Example:
                                        Nama Pemesan:
                                        No. Telp Pemesan:
                                        Nama Penerima:
                                        No. Telp Penerima:
                                        Alamat Kirim:
                                        Tanggal Pesanan:
                                        Jam Kirim:
                                        Pesanan:
                                        Adds-on:
                                        Wish / Greeting:
                                        Pengiriman: Kurir / Pickup
                                        Notes:
                                        Foto Referensi (optional):
                                    """)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .allowsHitTesting(false)
                                    }
                                }
                            )
                        
//                        // ✅ Show result from ViewModel
//                        if let json = viewModel.resultJSON {
//                            Text("✅ Template JSON:")
//                                .font(.headline)
//                                .padding(.top)
//                            ScrollView {
//                                Text(json)
//                                    .font(.system(.caption, design: .monospaced))
//                                    .padding()
//                                    .background(Color(.secondarySystemBackground))
//                                    .cornerRadius(10)
//                            }
//                        }
//                        
//                        // ✅ Show error from ViewModel
//                        if let error = viewModel.errorMessage {
//                            Text("❌ Error: \(error)")
//                                .foregroundColor(.red)
//                                .padding(.top)
//                        }
                    }
                    .padding()
                }
                
                // ✅ Simplified button
                Button(action: {
                    Task {
                        await viewModel.generateTemplate(from: formPesanan)
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(30)
                            .padding(.horizontal)
                    } else {
                        Text("Tinjau Formulir Pesanan")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(30)
                            .padding(.horizontal)
                            .shadow(radius: 5)
                    }
                }
                .disabled(formPesanan.isEmpty || viewModel.isLoading)
            }
            .navigationDestination(isPresented: $viewModel.didSave) {
                EditTemplateFormView(path: $path)
            }
        }
        .task {
            viewModel.configure(userId: session.userId)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeOut(duration: 0.12)) { keyboardVisible = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.12)) { keyboardVisible = false }
        }
    }
}

//#Preview {
//    let session = SessionManager()
//    session.isSignedIn = true
//    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
//    
//    return NewTemplateFormView()
//        .environmentObject(session)
//}

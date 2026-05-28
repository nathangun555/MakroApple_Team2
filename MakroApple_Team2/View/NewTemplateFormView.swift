import SwiftUI
import Foundation

struct NewTemplateFormView: View {
    
    @State private var formPesanan = ""
    @State private var viewModel = NewTemplateViewModel()
    @EnvironmentObject var session: SessionManager
    @FocusState private var isTextEditorFocused: Bool
    
    @Binding var isDismissed: Bool
    
    @Environment(\.dismiss) private var dismiss
    
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
                        }
                        
                        TextEditor(text: $formPesanan)
                            .padding(3)
                            .frame(height: geometry.size.height / 3)
                            .focused($isTextEditorFocused)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(5), lineWidth: 0.5)
                            )
                            .overlay(
                                Group {
                                    if formPesanan.isEmpty && !isTextEditorFocused {
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
                
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundStyle(.primaryButton)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        if formPesanan.isEmpty{
                            Button {
                                Task {
                                    
                                }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.title3)
                                        .foregroundColor(.primaryButton)
                                }
                            }
                            .buttonStyle(.glassProminent)
                            .tint(.white)
                        }
                        else {
                            
                            Button {
                                Task {
                                    await viewModel.generateTemplate(from: formPesanan)
                                }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(.glassProminent)
                            .tint(.primaryButton)
                            .disabled(viewModel.isLoading)
                        }
                        
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
            }
            .opacity(viewModel.isLoading ? 0 : 1)
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle("Formulir Pesanan")
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $viewModel.didSave) {
                EditTemplateFormView(isDismissed: $isDismissed)
            }
            if viewModel.isLoading {
                LoadingView(context: "template form")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .task {
            viewModel.configure(userId: session.userId)
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

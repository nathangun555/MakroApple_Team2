//
//  NewTemplateFormView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 21/10/25.
//

import SwiftUI
import Foundation

struct NewTemplateFormView: View {
    
    @State private var formPesanan = ""
    @State private var isLoading = false
    @State private var resultJSON: String? = nil
    @State private var errorMessage: String? = nil
    @State private var viewModel = NewTemplateViewModel()
    @EnvironmentObject var session: SessionManager
    
    let edgeFunctionURL = URL(string: "https://iznjcwyoziqjgfjahemb.supabase.co/functions/v1/form-template")!
    
    var body: some View {
        NavigationStack {
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
                                        if formPesanan.isEmpty {
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
                            if let json = resultJSON {
                                Text("✅ Template JSON:")
                                    .font(.headline)
                                    .padding(.top)
                                ScrollView {
                                    Text(json)
                                        .font(.system(.caption, design: .monospaced))
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(10)
                                }
                            }
                            
                            if let error = errorMessage ?? viewModel.errorMessage {
                                Text("❌ Error: \(error)")
                                    .foregroundColor(.red)
                                    .padding(.top)
                            }
                        }
                        .padding()
                    }
                    
                    Button(action: {
                        Task {
                            await sendToEdgeFunction()
                        }
                    }) {
                        if isLoading || viewModel.isLoading {
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
                    .disabled(formPesanan.isEmpty || isLoading || viewModel.isLoading)
                }
                .navigationDestination(isPresented: $viewModel.didSave) {
                    EditTemplateFormView()
                }
            }
        }
        .task {
            viewModel.configure(userId: session.userId)
        }
    }
    
    // MARK: - Send Function
    func sendToEdgeFunction() async {
        guard !formPesanan.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        resultJSON = nil
        
        do {
            var request = URLRequest(url: edgeFunctionURL)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml6bmpjd3lvemlxamdmamFoZW1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY3MTg3NjksImV4cCI6MjA3MjI5NDc2OX0.J9zQpQajTg3V6qAN18W5Fkv2jCDobL_XzuRS3BdPmdA", forHTTPHeaderField: "Authorization")
            
            let body = ["input": formPesanan]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            if let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let outputObject = decoded["outputJson"] as? [String: Any] {
                if let jsonData = try? JSONSerialization.data(withJSONObject: outputObject, options: []),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    resultJSON = jsonString
                }
            } else {
                resultJSON = String(data: data, encoding: .utf8)
            }

            await viewModel.saveTemplate(templateString: resultJSON ?? "")
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
    
    let view = NewTemplateFormView()
    
    return view.environmentObject(session)
}

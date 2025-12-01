//
//  ChatBotView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 21/11/25.
//

import SwiftUI

struct ChatBotView: View {
    @EnvironmentObject var session: SessionManager
    @StateObject private var viewModel = ChatBotViewModel()
    
    private let suggestions = [
        "Apa pesanan saya dalam minggu ini?",
        "Berikan saya rangkuman penjualan dalam bulan ini",
        "Produk apa yang paling banyak dibeli pelanggan saya?",
        "Siapa pelanggan yang paling aktif?",
        "Berapa total pendapatan saya hari ini?",
        "Beri saya insight singkat dari performa toko minggu ini",
        "Bagaimana tren penjualan dibandingkan bulan lalu?",
        "Tolong rekomendasikan promosi terbaik untuk minggu ini"
    ]


    var body: some View {
        ZStack {
            Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    Divider().opacity(0.2)
                    messagesList
                    inputBar
                }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Image("AIVAAI")
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .shadow(radius: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text("AiVA AI")
                    .font(.headline)

                Text("Asisten AI untuk bisnismu")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Messages

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if viewModel.messages.isEmpty {
                    suggestedQuestions
                }
                
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { msg in
                        messageRow(msg)
                            .id(msg.id)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if viewModel.isSending {
                        typingRow
                            .id("typing-row") // penting: id khusus
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.messages.count) { _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.isSending) { _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    private var suggestedQuestions: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Pertanyaan cepat")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            LazyVStack(spacing: 10) {
                ForEach(suggestions, id: \.self) { question in
                    Button(action: {
                        Task {
                            viewModel.inputText = question
                            if let userId = session.userId {
                                await viewModel.sendMessage(userId: userId)
                            }
                        }
                    }) {
                        HStack {
                            Text(question)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 4)
    }


    private func scrollToBottom(proxy: ScrollViewProxy) {
        if viewModel.isSending {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                proxy.scrollTo("typing-row", anchor: .bottom)
            }
        } else if let lastId = viewModel.messages.last?.id {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }


    @ViewBuilder
    private func messageRow(_ msg: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            if msg.role == .assistant {
                // Avatar AIVA
                Image("AIVABot")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .shadow(radius: 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("AIVA Assistant")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(.init(msg.text))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .textSelection(.enabled)
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                }

                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Kamu")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(msg.text)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.primaryButton,
                                            Color.primaryButton.opacity(0.85)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: Color.primaryButton.opacity(0.35),
                                radius: 8, x: 0, y: 2)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8),
                                   value: msg.id)
                }
            }
        }
    }

    // MARK: - Typing row (inside chat)

    private var typingRow: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Image("AIVABot")
                .resizable()
                .scaledToFill()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
                .shadow(radius: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("AIVA Assistant")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Text("AIVA is typing…")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TypingDotsView(dotColor: .secondary)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
            }

            Spacer(minLength: 40)
        }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        VStack(spacing: 8) {
            Divider().opacity(0.2)

            HStack(spacing: 10) {
                ZStack(alignment: .leading) {
                    if viewModel.inputText.isEmpty {
                        Text("Tanya apa saja tentang bisnismu…")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 14)
                    }

                    TextField("", text: $viewModel.inputText, axis: .vertical)
                        .padding(12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 1)   // outline tipis abu gelap
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                )


                Button {
                    Task {
                        if let userId = session.userId {
                            await viewModel.sendMessage(userId: userId)
                        }
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(viewModel.canSend ? Color.primaryButton : Color.gray)
                        )
                }
                .disabled(!viewModel.canSend)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Typing dots animation

struct TypingDotsView: View {
    var dotColor: Color = .secondary
    @State private var animate = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animate ? 1.0 : 0.6)
                    .opacity(animate ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.12),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - ViewModel helper

extension ChatBotViewModel {
    var canSend: Bool {
        !isSending &&
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

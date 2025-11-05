//
//  VideoLoadingView.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 04/11/25.
//

import SwiftUI
import AVFoundation

struct VideoLoadingView: UIViewRepresentable {

    let player: AVQueuePlayer
    let looper: AVPlayerLooper

    init(videoName: String, fileExtension: String = "mp4") {
        let url = Bundle.main.url(forResource: videoName, withExtension: fileExtension)!
        let item = AVPlayerItem(url: url)

        self.player = AVQueuePlayer()
        self.looper = AVPlayerLooper(player: player, templateItem: item)
        self.player.play()
        self.player.isMuted = true
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = UIScreen.main.bounds
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) { }
}

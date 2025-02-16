//
//  PIP_DemoApp.swift
//  PIP_Demo
//
//  Created by Iris on 2025-02-16.
//

import AVKit
import SwiftUI

@main
struct PIP_DemoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    var body: some Scene {
        MenuBarExtra("PIP Demo", systemImage: "play.tv") {
            Button("打开 PIP") {
                if let window = appDelegate.window {
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }

            Divider()

            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var viewController: ViewController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let screenSize = NSScreen.main?.frame ?? .zero
        let windowSize = CGSize(width: 800, height: 600)

        window = NSWindow(
            contentRect: CGRect(
                x: (screenSize.width - windowSize.width) / 2,
                y: (screenSize.height - windowSize.height) / 2,
                width: windowSize.width,
                height: windowSize.height
            ),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.isReleasedWhenClosed = false

        viewController = ViewController()
        window.contentViewController = viewController
        window.isMovableByWindowBackground = true
        window.title = "AVPlayer PiP Demo"
        window.makeKeyAndOrderFront(nil)
        window.center()
    }
}

class ViewController: NSViewController {
    private var player: AVPlayer!
    private var playerView: AVPlayerView!
    private var actionPopUpButton: NSPopUpButton!
    private var statusLabel: NSTextField!  // 添加状态标签
    private var pipController: AVPictureInPictureController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        setupPlayerView()
        setupActionPopUpButton()
        setupStatusLabel()
        setupPIPButton()
        addCustomOverlay()
        loadVideo()
    }

    private func setupPlayerView() {
        playerView = AVPlayerView()
        ///
        playerView.translatesAutoresizingMaskIntoConstraints = false
        /// 控制panel的类型
        playerView.controlsStyle = .floating
        /// 是否允许PIP
        playerView.allowsPictureInPicturePlayback = true
        playerView.showsFrameSteppingButtons = true
        playerView.showsSharingServiceButton = true
        playerView.showsTimecodes = true

        // 设置 PIP 控制器
        if AVPictureInPictureController.isPictureInPictureSupported() {
            if let playerLayer = playerView.layer as? AVPlayerLayer {
                pipController = AVPictureInPictureController(
                    playerLayer: playerLayer)
            }
        }

        view.addSubview(playerView)

        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupActionPopUpButton() {
        actionPopUpButton = NSPopUpButton()
        actionPopUpButton.translatesAutoresizingMaskIntoConstraints = false
        actionPopUpButton.addItems(withTitles: ["Play", "Pause", "Restart"])
        actionPopUpButton.target = self
        actionPopUpButton.action = #selector(handleActionSelection)
        view.addSubview(actionPopUpButton)

        NSLayoutConstraint.activate([
            actionPopUpButton.topAnchor.constraint(
                equalTo: view.topAnchor, constant: 10),
            actionPopUpButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -10),
        ])
    }

    @objc private func handleActionSelection() {
        switch actionPopUpButton.titleOfSelectedItem {
        case "Play":
            player.play()
            statusLabel.stringValue = "Playing"
        case "Pause":
            player.pause()
            statusLabel.stringValue = "Paused"
        case "Restart":
            player.seek(to: .zero)
            player.play()
            statusLabel.stringValue = "Playing"
        default:
            break
        }
    }

    private func setupStatusLabel() {
        statusLabel = NSTextField(labelWithString: "Playing")
        statusLabel.font = NSFont.systemFont(ofSize: 14)
        statusLabel.textColor = .white
        statusLabel.backgroundColor = .black
        statusLabel.isBezeled = false
        statusLabel.drawsBackground = true
        statusLabel.isEditable = false
        statusLabel.alignment = .center
        statusLabel.isHidden = true  // 初始隐藏
        view.addSubview(statusLabel)
    }

    private func setupPIPButton() {
        let pipButton = NSButton(
            title: "进入画中画", target: self, action: #selector(togglePIP))
        pipButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pipButton)

        NSLayoutConstraint.activate([
            pipButton.topAnchor.constraint(
                equalTo: view.topAnchor, constant: 10),
            pipButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 10),
        ])
    }

    @objc private func togglePIP() {
        guard let pipController = pipController else { return }

        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else {
            pipController.startPictureInPicture()
        }
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        // 确保 playerView 已经有内容
        guard let playerView = playerView else { return }

        // 获取 videoBounds
        let videoRect = playerView.videoBounds

        print(videoRect.size)

        // 设置状态标签的位置
        let labelHeight: CGFloat = 20
        statusLabel.frame = CGRect(
            x: videoRect.origin.x,
            y: videoRect.origin.y + videoRect.height - labelHeight - 10,
            width: videoRect.width,
            height: labelHeight
        )
        statusLabel.isHidden = false
        //        resizeWindowToFitVideo()
    }

    // 添加自定义覆盖视图
    private func addCustomOverlay() {
        guard let overlayView = playerView.contentOverlayView else { return }

        // 创建并配置 NSHostingView
        let hostingView = createHostingView()
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.frame = CGRect(x: 100, y: 100, width: 200, height: 50)

        // 添加到覆盖层
        overlayView.addSubview(hostingView)

        // 设置布局约束（示例：居中显示）
        NSLayoutConstraint.activate([
            hostingView.centerXAnchor.constraint(
                equalTo: overlayView.centerXAnchor),
            hostingView.centerYAnchor.constraint(
                equalTo: overlayView.centerYAnchor),
        ])
    }

    struct CustomOverlayView: View {
        var body: some View {
            Text("123")
                .padding(10)
                .background(Color.black.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(5)
        }
    }

    // 创建 NSHostingView 包装器
    private func createHostingView() -> NSView {
        let swiftUIView = CustomOverlayView()
        return NSHostingView(rootView: swiftUIView)
    }

    private func loadVideo() {
        guard
            let url = URL(
                string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")
        else { return }
        player = AVPlayer(url: url)
        playerView.player = player
        player.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.resizeWindowToFitVideo()
        }
    }
    private func resizeWindowToFitVideo() {
        guard let window = view.window else { return }
        var frame = window.frame
        frame.size = playerView.videoBounds.size
        window.setFrame(frame, display: true, animate: true)
        window.center()
    }
}

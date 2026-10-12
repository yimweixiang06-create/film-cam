import SwiftUI

@main
struct FilmStyleCameraApp: App {
    var body: some Scene {
        WindowGroup {
            CameraHomeView()
                .preferredColorScheme(.dark)
        }
    }
}

import SwiftData

enum ContainerLoadState {
    case loading
    case ready(ModelContainer)
    case failed(StartupError)
}

import AVFoundation

enum WallpaperScalingMode: String, CaseIterable, Hashable {
    case fill
    case fit
    case stretch

    var displayName: String {
        rawValue.capitalized
    }

    var avVideoGravity: AVLayerVideoGravity {
        switch self {
        case .fill:
            return .resizeAspectFill

        case .fit:
            return .resizeAspect

        case .stretch:
            return .resize
        }
    }
}
